import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationsNotifier extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  @override
  FutureOr<List<NotificationModel>> build() async {
    return _fetchNotifications();
  }

  Future<List<NotificationModel>> _fetchNotifications() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/notifications');
    final data = response.data as List;
    return data.map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<void> markAsRead(String id) async {
    final previousState = state.value;
    
    // Optimistic update
    if (previousState != null) {
      state = AsyncData(
        previousState.map((e) {
          if (e.id == id) {
            return e.copyWith(isRead: true);
          }
          return e;
        }).toList(),
      );
    }

    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/notifications/$id/read');
    } catch (e, st) {
      // Revert on error
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      state = AsyncError(e, st);
    }
  }
}

final notificationsProvider = AutoDisposeAsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);
