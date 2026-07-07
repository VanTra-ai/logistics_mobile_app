import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shipment/models/shipment_model.dart'; // import OrderModel from here
import '../../../core/network/api_client.dart';

final shipperOrdersProvider =
    StateNotifierProvider<ShipperOrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return ShipperOrdersNotifier(ref);
});

class ShipperOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final Ref _ref;

  ShipperOrdersNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      state = const AsyncValue.loading();
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/orders/me');
      
      final data = response.data['data'] as List;
      final orders = data.map((json) => OrderModel.fromJson(json)).toList();
      
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await fetchOrders();
  }
}
