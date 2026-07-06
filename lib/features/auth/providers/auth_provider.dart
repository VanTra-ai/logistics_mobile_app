import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Trạng thái xác thực của ứng dụng.
class AuthState {
  /// Người dùng đã đăng nhập (null nếu chưa đăng nhập).
  final UserModel? user;

  /// Đang thực hiện thao tác bất đồng bộ (đăng nhập / kiểm tra token).
  final bool isLoading;

  /// Thông báo lỗi nếu thao tác thất bại.
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// Đăng nhập với email và password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.login(email: email, password: password);
      state = state.copyWith(isLoading: false, user: result.user);
      return true;
    } on Exception catch (e) {
      final message = _parseError(e);
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  /// Đăng xuất, xoá token và reset state.
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  /// Xoá thông báo lỗi hiện tại.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Chuyển đổi exception thành thông báo thân thiện.
  String _parseError(Exception e) {
    // DioException sẽ có response body từ Backend
    final str = e.toString();
    if (str.contains('401') || str.contains('Unauthorized')) {
      return 'Email hoặc mật khẩu không chính xác.';
    }
    if (str.contains('SocketException') || str.contains('connection')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.';
    }
    if (str.contains('timeout')) {
      return 'Kết nối đã hết thời gian chờ. Thử lại sau.';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provider cho AuthNotifier — quản lý trạng thái đăng nhập.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// Provider kiểm tra trạng thái đăng nhập lúc khởi động ứng dụng.
/// Trả về true nếu đang có access_token hợp lệ trong Secure Storage.
final authStatusProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(authRepositoryProvider);
  return repository.hasValidToken();
});
