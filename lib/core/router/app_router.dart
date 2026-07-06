import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/main_shell_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/station/screens/station_scan_screen.dart';
import '../../features/shipment/screens/shipment_list_screen.dart';
import '../../features/shipment/screens/shipment_detail_screen.dart';
import '../storage/secure_storage_provider.dart';

/// Danh sách tên các route để tránh hardcode string.
abstract class AppRoutes {
  // Ngoài shell
  static const String login = '/';

  // Trong shell (BottomNav)
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // Sub-routes (push on top of shell)
  static const String station = '/station';
  static const String shipments = '/shipments';
  static const String shipmentDetail = '/shipments/:id';
}

/// Provider cho GoRouter — được tạo một lần và tái sử dụng xuyên suốt.
final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(secureStorageProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    /// Guard: Kiểm tra JWT Token mỗi lần điều hướng.
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

      return null;
    },

    routes: [
      // ── Màn hình Đăng nhập (ngoài shell) ──
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Màn hình Quét mã Bưu cục (push on top, không thuộc BottomNav) ──
      GoRoute(
        path: AppRoutes.station,
        name: 'station',
        builder: (context, state) => const StationScanScreen(),
      ),

      // ── Màn hình Danh sách Chuyến xe (push on top) ──
      GoRoute(
        path: AppRoutes.shipments,
        name: 'shipments',
        builder: (context, state) => const ShipmentListScreen(),
      ),

      // ── Màn hình Chi tiết Chuyến xe (push on top) ──
      GoRoute(
        path: AppRoutes.shipmentDetail,
        name: 'shipmentDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ShipmentDetailScreen(shipmentId: id);
        },
      ),

      // ── Shell chứa BottomNavigationBar ──
      ShellRoute(
        builder: (context, state, child) =>
            MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Phương thức tiện ích để làm mới trạng thái đăng nhập.
void refreshRouter(Ref ref) {
  ref.invalidate(authStatusProvider);
}
