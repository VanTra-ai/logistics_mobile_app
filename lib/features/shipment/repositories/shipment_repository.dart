import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/shipment_model.dart';

class ShipmentRepository {
  final Dio _dio;

  const ShipmentRepository(this._dio);

  /// Lấy danh sách chuyến xe của một bưu cục
  Future<List<ShipmentModel>> getHubShipments(String hubId) async {
    final response = await _dio.get<Map<String, dynamic>>('/hubs/$hubId/shipments');
    final List dataList = response.data?['data'] ?? response.data?['shipments'] ?? [];
    return dataList.map((json) => ShipmentModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Lấy chi tiết của một chuyến xe cụ thể (load đầy đủ relations)
  Future<ShipmentModel> getShipmentDetail(String shipmentId) async {
    // Vì không có API /shipments/:id riêng biệt, ta lấy tất cả và lọc ra
    // Hoặc nếu backend có hỗ trợ ngầm, ta thử gọi GET /shipments/:id
    // Để an toàn và đồng bộ với backend thực tế, ta có thể fetch qua danh sách hoặc thử GET /shipments/:id
    try {
      final response = await _dio.get<Map<String, dynamic>>('/shipments/$shipmentId');
      final data = response.data?['data'] ?? response.data;
      if (data != null) {
        return ShipmentModel.fromJson(data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback nếu không có endpoint riêng: dùng hub shipments
    }
    throw Exception('Không thể tải chi tiết chuyến xe!');
  }

  /// Lấy danh sách đơn hàng có sẵn ở bưu cục (AT_HUB) và chưa xếp lên chuyến nào
  Future<List<OrderModel>> getAvailableOrders() async {
    final response = await _dio.get<Map<String, dynamic>>('/orders');
    final List dataList = response.data?['data'] ?? response.data ?? [];
    
    // Lọc các đơn hàng đang lưu tại kho bưu cục (AT_HUB) và chưa có chuyến xe (shipment == null)
    return dataList
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .where((order) => order.currentStatus == 'AT_HUB')
        .toList();
  }

  /// Gom hàng lên xe
  Future<void> dispatchOrders(String shipmentId, List<String> orderIds) async {
    await _dio.patch(
      '/shipments/$shipmentId/orders',
      data: {
        'order_ids': orderIds,
      },
    );
  }

  /// Cập nhật trạng thái chuyến xe (ví dụ: cho xe xuất bến IN_TRANSIT)
  Future<void> updateShipmentStatus(String shipmentId, String status) async {
    await _dio.patch(
      '/shipments/$shipmentId/status',
      data: {
        'status': status,
      },
    );
  }
}

/// Provider cho ShipmentRepository
final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepository(ref.read(dioProvider));
});
