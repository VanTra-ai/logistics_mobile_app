import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider cho FlutterSecureStorage, dùng xuyên suốt ứng dụng.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

/// Tên khoá lưu JWT Token trong secure storage.
abstract class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
}
