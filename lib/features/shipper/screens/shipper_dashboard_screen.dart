import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/label_service.dart';
import '../../auth/models/user_model.dart';
import '../../tms/services/location_tracker_service.dart';
import '../providers/shipper_orders_provider.dart';

class ShipperDashboardScreen extends ConsumerWidget {
  final UserModel user;

  const ShipperDashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize location tracking
    ref.read(locationTrackerServiceProvider).startTracking();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ordersAsync = ref.watch(shipperOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bảng điều khiển Shipper', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shipperOrdersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('Bạn không có đơn hàng nào đang chờ giao.'));
          }

          final sortedOrders = List.of(orders)
            ..sort((a, b) => a.deliverySequence.compareTo(b.deliverySequence));
          
          return RefreshIndicator(
            onRefresh: () => ref.read(shipperOrdersProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedOrders.length,
              itemBuilder: (context, index) {
                final order = sortedOrders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(order.trackingNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Nhận: ${order.receiverName}'),
                        Text('Đ/c: ${order.receiverAddress}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('COD: ${order.codAmount} đ', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (order.latitude != null && order.longitude != null)
                          IconButton(
                            icon: const Icon(Icons.navigation, color: Colors.green),
                            onPressed: () async {
                              final uri = Uri.parse('google.navigation:q=${order.latitude},${order.longitude}');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Không thể mở Google Maps')),
                                  );
                                }
                              }
                            },
                            tooltip: 'Dẫn đường',
                          ),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          onPressed: () async {
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đang tải nhãn in...')),
                              );
                              await ref.read(labelServiceProvider).downloadAndOpenLabel(order.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          tooltip: 'Xem / In nhãn',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lỗi: $err'),
              ElevatedButton(
                onPressed: () => ref.read(shipperOrdersProvider.notifier).refresh(),
                child: const Text('Thử lại'),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/shipper/scan'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Quét giao hàng'),
      ),
    );
  }
}
