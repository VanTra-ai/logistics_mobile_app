import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/secure_storage_provider.dart';

/// Base URL trỏ tới Backend NestJS.
/// 10.0.2.2 là địa chỉ đặc biệt của Android Emulator trỏ về localhost của máy host.
const String _baseUrl = 'http://10.0.2.2:3333';

/// Interceptor tự động gắn JWT Token vào header và bắt lỗi 401.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: StorageKeys.accessToken);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token đã hết hạn hoặc không hợp lệ.
      // Xoá token cũ ra khỏi storage để buộc đăng nhập lại.
      await _storage.delete(key: StorageKeys.accessToken);

      // TODO: Có thể thêm logic refresh token ở đây trước khi đăng xuất.
      // Hoặc bắn sự kiện toàn cục để trigger màn hình đăng nhập.
      debugPrint('[AuthInterceptor] 401 Unauthorized — Đã xoá token, cần đăng nhập lại.');
    }

    handler.next(err);
  }
}

/// Provider cho đối tượng Dio đã được cấu hình đầy đủ.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Gắn Interceptor bắt token và lỗi 401
  dio.interceptors.add(AuthInterceptor(storage));

  // Log request/response trong môi trường debug
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (object) => debugPrint('[DioLog] $object'),
    ),
  );

  return dio;
});
