import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/api_client.dart';

final locationTrackerServiceProvider = Provider<LocationTrackerService>((ref) {
  final dio = ref.watch(dioProvider);
  return LocationTrackerService(dio);
});

class LocationTrackerService {
  final Dio _dio;
  Timer? _timer;

  LocationTrackerService(this._dio);

  void startTracking() {
    if (_timer != null) return;
    _checkPermissionAndFetch(); // Fetch immediately on start
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkPermissionAndFetch();
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkPermissionAndFetch() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _updateLocationOnServer(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _updateLocationOnServer(double lat, double lng) async {
    try {
      await _dio.patch('/users/location', data: {
        'latitude': lat,
        'longitude': lng,
      });
      debugPrint('Location updated successfully: lat=$lat, lng=$lng');
    } catch (e) {
      debugPrint('Failed to update location on server: $e');
    }
  }
}
