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
import '../../features/ticket/screens/ticket_create_screen.dart';
import '../../features/shipper/screens/shipper_scan_screen.dart';
import '../../features/wms/screens/putaway_screen.dart';
import '../../features/wms/screens/packaging_screen.dart';
import '../../features/wallet/screens/my_wallet_screen.dart';
import '../../features/wms/screens/audit_screen.dart';
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
  static const String wallet = '/wallet';
  static const String station = '/station';
  static const String shipments = '/shipments';
  static const String shipmentDetail = '/shipments/:id';
  static const String ticketCreate = '/tickets/create';
  static const String shipperScan = '/shipper/scan';

  // WMS routes
  static const String wmsPutaway = '/wms/putaway';
  static const String wmsPackaging = '/wms/packaging';
  static const String wmsAudit = '/wms/audit';
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

      // ── Màn hình Ví của tôi (push on top) ──
      GoRoute(
        path: AppRoutes.wallet,
        name: 'wallet',
        builder: (context, state) => const MyWalletScreen(),
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

      // ── Màn hình Báo cáo Sự cố (push on top) ──
      GoRoute(
        path: AppRoutes.ticketCreate,
        name: 'ticketCreate',
        builder: (context, state) {
          final prefilledId = state.uri.queryParameters['orderId'];
          return TicketCreateScreen(prefilledOrderId: prefilledId);
        },
      ),

      // ── Màn hình Quét Giao Hàng Shipper (push on top) ──
      GoRoute(
        path: AppRoutes.shipperScan,
        name: 'shipperScan',
        builder: (context, state) => const ShipperScanScreen(),
      ),

      // ── WMS Routes (push on top) ──
      GoRoute(
        path: AppRoutes.wmsPutaway,
        name: 'wmsPutaway',
        builder: (context, state) => const PutawayScreen(),
      ),
      GoRoute(
        path: AppRoutes.wmsPackaging,
        name: 'wmsPackaging',
        builder: (context, state) => const PackagingScreen(),
      ),
      GoRoute(
        path: AppRoutes.wmsAudit,
        name: 'wmsAudit',
        builder: (context, state) => const AuditScreen(),
      ),

      // ── ShellRoute chứa BottomNavigationBar ──
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
