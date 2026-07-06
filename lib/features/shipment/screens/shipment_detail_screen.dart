import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shipment_model.dart';
import '../providers/shipment_provider.dart';
import '../repositories/shipment_repository.dart';

class ShipmentDetailScreen extends ConsumerStatefulWidget {
  final String shipmentId;

  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends ConsumerState<ShipmentDetailScreen> {
  final List<String> _selectedOrderIds = [];
  bool _isDispatching = false;

  @override
  Widget build(BuildContext context) {
    final shipmentsAsync = ref.watch(shipmentListProvider);
    final availableOrdersAsync = ref.watch(availableOrdersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Tìm kiếm chuyến xe từ danh sách đã tải
    final shipment = shipmentsAsync.valueOrNull?.firstWhere(
      (s) => s.id == widget.shipmentId,
    );

    if (shipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chuyến xe')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final fillRate = shipment.fillRate;
    final fillPercent = (fillRate * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: Text(shipment.shipmentCode ?? 'Chi tiết chuyến xe'),
      ),
      body: Column(
        children: [
          // ── Thông tin tóm tắt chuyến xe ──
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      shipment.vehicleNumber,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _statusLabel(shipment.status),
                      style: TextStyle(
                        color: shipment.status == 'PENDING'
                            ? Colors.amber.shade800
                            : Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tài xế: ${shipment.shipper?.fullName ?? "Chưa có"} (${shipment.shipper?.email ?? ""})',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tải trọng hiện tại',
                      style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      '${shipment.currentWeight.toStringAsFixed(1)} / ${shipment.capacityWeight.toStringAsFixed(0)} kg ($fillPercent%)',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: fillRate,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  color: fillRate > 0.9 ? Colors.red : colorScheme.primary,
                ),
              ],
            ),
          ),

          // ── Chia tab: Đơn đã lên xe / Đơn chờ gom ──
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Đơn hàng trên xe'),
                      Tab(text: 'Hàng chờ gom ở kho'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Đơn hàng đã lên xe
                        _AssignedOrdersTab(
                          orders: shipment.orders ?? [],
                          colorScheme: colorScheme,
                        ),

                        // Tab 2: Hàng chờ gom
                        availableOrdersAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Lỗi tải hàng chờ: $err')),
                          data: (availableOrders) {
                            if (availableOrders.isEmpty) {
                              return const Center(
                                child: Text('Không có đơn hàng nào chờ gom tại kho!'),
                              );
                            }

                            return Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: availableOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = availableOrders[index];
                                      final isSelected = _selectedOrderIds.contains(order.id);

                                      return Card(
                                        child: CheckboxListTile(
                                          title: Text(
                                            order.trackingNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Khối lượng: ${order.weight} kg\nĐến: ${order.receiverAddress}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          value: isSelected,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedOrderIds.add(order.id);
                                              } else {
                                                _selectedOrderIds.remove(order.id);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Nút xác nhận điều phối gom đơn
                                if (_selectedOrderIds.isNotEmpty)
                                  SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: FilledButton(
                                        onPressed: _isDispatching ? null : _handleDispatchOrders,
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size.fromHeight(50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isDispatching
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                'Xác nhận điều phối ${_selectedOrderIds.length} đơn lên xe',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDispatchOrders() async {
    setState(() {
      _isDispatching = true;
    });

    try {
      final repository = ref.read(shipmentRepositoryProvider);
      await repository.dispatchOrders(widget.shipmentId, _selectedOrderIds);

      // Invalidate để tải lại danh sách đơn hàng khả dụng & refresh chuyến xe
      ref.invalidate(availableOrdersProvider);
      await ref.read(shipmentListProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Điều phối hàng lên chuyến xe thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _selectedOrderIds.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi điều phối: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDispatching = false;
        });
      }
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'PENDING' => 'ĐANG CHỜ GOM',
      'IN_TRANSIT' => 'ĐANG DI CHUYỂN',
      'COMPLETED' || 'ARRIVED' => 'ĐÃ ĐẾN NƠI',
      _ => status,
    };
  }
}

class _AssignedOrdersTab extends StatelessWidget {
  final List<OrderModel> orders;
  final ColorScheme colorScheme;

  const _AssignedOrdersTab({required this.orders, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('Chưa có đơn hàng nào được xếp lên xe này!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              order.trackingNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
            subtitle: Text(
              'Đến: ${order.receiverAddress}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${order.weight} kg',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
