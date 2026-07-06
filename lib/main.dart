import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  // Đảm bảo Flutter binding được khởi tạo trước khi truy cập các platform channel
  // (cần thiết cho flutter_secure_storage).
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // Bọc toàn bộ ứng dụng trong ProviderScope để kích hoạt Riverpod
    const ProviderScope(
      child: LogisticsApp(),
    ),
  );
}

/// Widget gốc của ứng dụng.
/// Sử dụng ConsumerWidget để đọc các Provider từ Riverpod.
class LogisticsApp extends ConsumerWidget {
  const LogisticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Đọc trạng thái khởi tạo tài khoản (JWT + nạp Profile)
    final authStatus = ref.watch(authStatusProvider);

    return authStatus.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping_rounded, size: 64, color: Color(0xFF1565C0)),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Lỗi khởi động ứng dụng: $err'),
          ),
        ),
      ),
      data: (_) {
        // Đọc GoRouter từ Provider sau khi khởi tạo thành công
        final router = ref.watch(appRouterProvider);

        return MaterialApp.router(
          title: 'VanTra Logistics',
          debugShowCheckedModeBanner: false,

          // Cấu hình theme cơ bản
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0), // Xanh dương VanTra
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,

          // Kết nối với GoRouter
          routerConfig: router,
        );
      },
    );
  }
}
