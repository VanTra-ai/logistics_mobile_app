import 'package:flutter/material.dart';

/// Màn hình Thông báo — sẽ được xây dựng sau.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa có thông báo mới', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
