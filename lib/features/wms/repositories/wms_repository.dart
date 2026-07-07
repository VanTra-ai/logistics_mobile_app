import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Repository đảm nhận toàn bộ logic gọi API cho module WMS.
class WmsRepository {
  final Dio _dio;

  const WmsRepository(this._dio);

  /// Cất hàng vào vị trí: PATCH /orders/$orderId/putaway
  Future<Map<String, dynamic>> putaway(String orderId, String barcode) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/orders/$orderId/putaway',
      data: {'barcode': barcode},
    );
    return response.data ?? {};
  }

  /// Lấy danh sách vật liệu đóng gói: GET /materials
  Future<List<dynamic>> getMaterials() async {
    final response = await _dio.get<List<dynamic>>('/materials');
    return response.data ?? [];
  }

  /// Đóng gói đơn hàng: POST /orders/$orderId/package
  Future<Map<String, dynamic>> packageOrder(
    String orderId,
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/package',
      data: {'items': items},
    );
    return response.data ?? {};
  }

  /// Lấy danh sách phiên kiểm kê: GET /audits
  Future<List<dynamic>> getAudits({String? status}) async {
    final response = await _dio.get<List<dynamic>>(
      '/audits',
      queryParameters: status != null ? {'status': status} : null,
    );
    return response.data ?? [];
  }

  /// Gửi kết quả quét kiểm kê: POST /audits/$auditId/submit
  Future<Map<String, dynamic>> submitAuditScan(
    String auditId,
    String locationBarcode,
    List<String> trackingNumbers,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/audits/$auditId/submit',
      data: {
        'location_barcode': locationBarcode,
        'tracking_numbers': trackingNumbers,
      },
    );
    return response.data ?? {};
  }
}

/// Provider cho WmsRepository.
final wmsRepositoryProvider = Provider<WmsRepository>((ref) {
  return WmsRepository(ref.read(dioProvider));
});
