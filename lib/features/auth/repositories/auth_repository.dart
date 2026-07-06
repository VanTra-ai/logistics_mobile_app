import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../models/user_model.dart';

/// Kết quả trả về sau khi đăng nhập thành công.
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

/// Repository thực hiện toàn bộ logic gọi API Auth.
class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  const AuthRepository(this._dio, this._storage);

  /// Đăng nhập và lưu token vào Secure Storage.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = response.data!;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    // Lưu cả hai token vào Secure Storage
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
    ]);

    return LoginResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  /// Kiểm tra xem ứng dụng đang có token hợp lệ hay không.
  Future<bool> hasValidToken() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  /// Lấy thông tin cá nhân của người dùng đang đăng nhập (bao gồm cả bưu cục)
  Future<UserModel> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/users/profile');
    return UserModel.fromJson(response.data!);
  }

  /// Đăng xuất: xóa sạch toàn bộ token khỏi Secure Storage.
  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
    ]);
  }
}

/// Provider cho AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(secureStorageProvider),
  );
});
