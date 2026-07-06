import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

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
    // Đọc GoRouter từ Provider
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'VanTra Logistics',
      debugShowCheckedModeBanner: false,

      // Cấu hình theme cơ bản — sẽ được mở rộng sau
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
  }
}
