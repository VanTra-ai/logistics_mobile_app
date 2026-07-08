import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

final labelServiceProvider = Provider<LabelService>((ref) {
  return LabelService(ref.read(dioProvider));
});

class LabelService {
  final Dio _dio;

  LabelService(this._dio);

  /// Tải file PDF từ API và mở thông qua ứng dụng đọc PDF hệ thống
  Future<void> downloadAndOpenLabel(String orderId) async {
    try {
      final response = await _dio.get(
        '/orders/$orderId/label',
        options: Options(
          responseType: ResponseType.bytes,
          // Đảm bảo request không bị cache
          headers: {'Cache-Control': 'no-cache'},
        ),
      );

      // Lấy thư mục tạm thời của thiết bị
      final tempDir = await getTemporaryDirectory();
      
      // Tạo file PDF
      final file = File('${tempDir.path}/label_$orderId.pdf');
      
      // Ghi bytes vào file
      await file.writeAsBytes(response.data);

      // Mở file bằng ứng dụng hệ thống
      final result = await OpenFilex.open(file.path);
      
      if (result.type != ResultType.done) {
        throw Exception('Không thể mở file: ${result.message}');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi mạng khi tải nhãn in: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi khi mở nhãn in: $e');
    }
  }
  /// Tải file Excel biên bản chuyến xe từ API và mở
  Future<void> downloadAndOpenManifest(String shipmentId) async {
    try {
      final response = await _dio.get(
        '/exports/orders?shipmentId=$shipmentId',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Cache-Control': 'no-cache'},
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/bien-ban-$shipmentId.xlsx');
      await file.writeAsBytes(response.data);

      final result = await OpenFilex.open(file.path);
      
      if (result.type != ResultType.done) {
        throw Exception('Không thể mở file Excel: ${result.message}');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi mạng khi tải biên bản: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi khi mở biên bản: $e');
    }
  }
}
