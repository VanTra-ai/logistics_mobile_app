import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../models/shipment_model.dart';
import '../providers/shipment_provider.dart';

class ShipmentListScreen extends ConsumerWidget {
  const ShipmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentsAsync = ref.watch(shipmentListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều phối Chuyến xe'),
      ),
      body: shipmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Lỗi tải danh sách chuyến xe',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(shipmentListProvider.notifier).refresh(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (shipments) {
          if (shipments.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(shipmentListProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có chuyến xe nào được lập',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kéo xuống để làm mới dữ liệu',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
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

          return RefreshIndicator(
            onRefresh: () => ref.read(shipmentListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: shipments.length,
              itemBuilder: (context, index) {
                final shipment = shipments[index];
                return _ShipmentCard(shipment: shipment, theme: theme);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final ShipmentModel shipment;
  final ThemeData theme;

  const _ShipmentCard({required this.shipment, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final fillRate = shipment.fillRate;
    final fillPercent = (fillRate * 100).toStringAsFixed(0);

    // Xác định màu sắc theo trạng thái
    final Color statusColor = switch (shipment.status) {
      'PENDING' => Colors.amber.shade700,
      'IN_TRANSIT' => Colors.blue.shade700,
      'COMPLETED' || 'ARRIVED' => Colors.green.shade700,
      _ => colorScheme.onSurface,
    };

    final Color statusBg = switch (shipment.status) {
      'PENDING' => Colors.amber.shade50,
      'IN_TRANSIT' => Colors.blue.shade50,
      'COMPLETED' || 'ARRIVED' => Colors.green.shade50,
      _ => colorScheme.surfaceContainerHighest,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.shipments}/${shipment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Code & Status ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shipment.shipmentCode ?? 'Mã chuyến: SHP—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(shipment.status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Thông tin Xe & Tài xế ──
              Row(
                children: [
                  const Icon(Icons.airport_shuttle_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Biển số: ',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  Text(
                    shipment.vehicleNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_pin_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Tài xế: ',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  Text(
                    shipment.shipper?.fullName ?? 'Chưa phân công',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Progress Bar tải trọng ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Độ đầy tải trọng (kg)',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  Text(
                    '${shipment.currentWeight.toStringAsFixed(1)} / ${shipment.capacityWeight.toStringAsFixed(0)} kg ($fillPercent%)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: fillRate > 0.9 ? Colors.red : colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: fillRate,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: fillRate > 0.9
                    ? Colors.red
                    : (fillRate > 0.7 ? Colors.orange : colorScheme.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lộ trình: ${shipment.originHub?.name ?? 'Kho gốc'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Icon(
                    Icons.arrow_right_alt,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  Text(
                    shipment.destinationHub?.name ?? 'Khách hàng',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
