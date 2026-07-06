import 'package:flutter/material.dart';

/// Màn hình đăng nhập rỗng — sẽ được xây dựng sau.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Màn hình Đăng nhập',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
