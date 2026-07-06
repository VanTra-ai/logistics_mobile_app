import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/shipment_model.dart';
import '../repositories/shipment_repository.dart';

/// Notifier quản lý danh sách chuyến xe liên kết với bưu cục hiện tại của người dùng.
class ShipmentListNotifier extends AutoDisposeAsyncNotifier<List<ShipmentModel>> {
  @override
  FutureOr<List<ShipmentModel>> build() async {
    final authState = ref.watch(authProvider);
    final hubId = authState.user?.hub?.id;
    if (hubId == null) {
      return [];
    }
    return ref.read(shipmentRepositoryProvider).getHubShipments(hubId);
  }

  /// Kéo để làm mới (Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authProvider);
      final hubId = authState.user?.hub?.id;
      if (hubId == null) return [];
      return ref.read(shipmentRepositoryProvider).getHubShipments(hubId);
    });
  }
}

/// Provider quản lý danh sách chuyến xe
final shipmentListProvider =
    AsyncNotifierProvider.autoDispose<ShipmentListNotifier, List<ShipmentModel>>(() {
  return ShipmentListNotifier();
});

/// Provider quản lý danh sách đơn hàng đang chờ xếp xe tại kho (AT_HUB)
final availableOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  return ref.read(shipmentRepositoryProvider).getAvailableOrders();
});
