import 'package:flutter/material.dart';

/// Màn hình Dashboard rỗng — sẽ được xây dựng sau.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Màn hình Dashboard',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
