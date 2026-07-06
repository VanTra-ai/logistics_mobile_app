import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Kết quả trả về từ một lần quét đơn hàng thành công.
class ScanResult {
  final String trackingNumber;
  final String message;

  const ScanResult({required this.trackingNumber, required this.message});
}

/// Repository đảm nhận toàn bộ logic gọi API quét mã.
class StationRepository {
  final Dio _dio;

  const StationRepository(this._dio);

  /// Quét nhập kho: POST /orders/scan-in
  /// Backend nhận `tracking_numbers: string[]` — gửi một mã mỗi lần.
  Future<ScanResult> scanIn(String trackingNumber) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/scan-in',
      data: {
        'tracking_numbers': [trackingNumber],
      },
    );

    final data = response.data ?? {};
    return ScanResult(
      trackingNumber: trackingNumber,
      message: data['message'] as String? ?? 'Nhập kho thành công!',
    );
  }

  /// Quét xuất kho: POST /orders/scan-out
  /// Xuất kho cần thêm `shipper_id` — hiện tại gửi null, sẽ bổ sung sau.
  Future<ScanResult> scanOut(String trackingNumber) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/scan-out',
      data: {
        'tracking_numbers': [trackingNumber],
      },
    );

    final data = response.data ?? {};
    return ScanResult(
      trackingNumber: trackingNumber,
      message: data['message'] as String? ?? 'Xuất kho thành công!',
    );
  }
}

/// Provider cho StationRepository.
final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository(ref.read(dioProvider));
});
