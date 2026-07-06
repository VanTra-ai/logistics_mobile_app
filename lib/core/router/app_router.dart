import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../storage/secure_storage_provider.dart';

/// Danh sách tên các route để tránh hardcode string.
abstract class AppRoutes {
  static const String login = '/';
  static const String dashboard = '/dashboard';
}

/// Provider cho GoRouter — được tạo một lần và tái sử dụng xuyên suốt.
final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(secureStorageProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],

    /// Guard: Kiểm tra JWT Token mỗi lần điều hướng.
    /// - Chưa có token → redirect về màn hình Login (/).
    /// - Đã có token + đang ở /  → redirect sang /dashboard.
    redirect: (context, state) async {
      final token = await storage.read(key: StorageKeys.accessToken);
      final isLoggedIn = token != null && token.isNotEmpty;
      final isOnLoginPage = state.matchedLocation == AppRoutes.login;

      // Chưa đăng nhập mà cố truy cập trang khác → về Login
      if (!isLoggedIn && !isOnLoginPage) {
        return AppRoutes.login;
      }

      // Đã đăng nhập mà vẫn ở trang Login → vào Dashboard
      if (isLoggedIn && isOnLoginPage) {
        return AppRoutes.dashboard;
      }

      // Không cần redirect
      return null;
    },
  );
});
