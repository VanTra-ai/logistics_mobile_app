import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/station_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum ScanMode { scanIn, scanOut }

enum ScanStatus { idle, processing, success, error }

// ─────────────────────────────────────────────────────────────────────────────
// Model: Một mục trong lịch sử quét phiên hiện tại
// ─────────────────────────────────────────────────────────────────────────────

class ScannedItem {
  final String trackingNumber;
  final ScanMode mode;
  final bool isSuccess;
  final String message;
  final DateTime timestamp;

  const ScannedItem({
    required this.trackingNumber,
    required this.mode,
    required this.isSuccess,
    required this.message,
    required this.timestamp,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class StationState {
  final ScanMode mode;
  final ScanStatus status;
  final String? lastMessage;
  final bool hasError;

  /// Danh sách các mã đã quét thành công trong phiên này (mới nhất ở đầu).
  final List<ScannedItem> sessionItems;

  const StationState({
    this.mode = ScanMode.scanIn,
    this.status = ScanStatus.idle,
    this.lastMessage,
    this.hasError = false,
    this.sessionItems = const [],
  });

  /// Đang bận xử lý hoặc đang chờ sau lỗi — chặn quét thêm.
  bool get isBusy => status == ScanStatus.processing || status == ScanStatus.error;

  StationState copyWith({
    ScanMode? mode,
    ScanStatus? status,
    String? lastMessage,
    bool? hasError,
    List<ScannedItem>? sessionItems,
  }) {
    return StationState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      hasError: hasError ?? this.hasError,
      sessionItems: sessionItems ?? this.sessionItems,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class StationNotifier extends StateNotifier<StationState> {
  final StationRepository _repository;

  StationNotifier(this._repository) : super(const StationState());

  /// Chuyển đổi chế độ Nhập kho / Xuất kho.
  void setMode(ScanMode mode) {
    if (state.isBusy) return;
    state = state.copyWith(mode: mode, status: ScanStatus.idle);
  }

  /// Xử lý mã vạch vừa quét được từ camera.
  Future<void> handleScan(String trackingNumber) async {
    // Chặn nếu đang xử lý hoặc đang trong thời gian chờ sau lỗi
    if (state.isBusy) return;

    // Chặn quét trùng mã trong phiên
    final alreadyScanned = state.sessionItems.any(
      (item) => item.trackingNumber == trackingNumber && item.isSuccess,
    );
    if (alreadyScanned) {
      state = state.copyWith(
        status: ScanStatus.error,
        lastMessage: 'Mã "$trackingNumber" đã được quét trong phiên này!',
        hasError: true,
      );
      await _pauseAfterError();
      return;
    }

    state = state.copyWith(status: ScanStatus.processing);

    try {
      final result = state.mode == ScanMode.scanIn
          ? await _repository.scanIn(trackingNumber)
          : await _repository.scanOut(trackingNumber);

      final item = ScannedItem(
        trackingNumber: trackingNumber,
        mode: state.mode,
        isSuccess: true,
        message: result.message,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        status: ScanStatus.success,
        lastMessage: result.message,
        hasError: false,
        sessionItems: [item, ...state.sessionItems],
      );

      // Reset về idle sau 0.8 giây
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        state = state.copyWith(status: ScanStatus.idle);
      }
    } on Exception catch (e) {
      final message = _parseError(e);
      final item = ScannedItem(
        trackingNumber: trackingNumber,
        mode: state.mode,
        isSuccess: false,
        message: message,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        status: ScanStatus.error,
        lastMessage: message,
        hasError: true,
        sessionItems: [item, ...state.sessionItems],
      );

      await _pauseAfterError();
    }
  }

  /// Xoá toàn bộ lịch sử quét của phiên hiện tại.
  void clearSession() {
    state = const StationState();
  }

  Future<void> _pauseAfterError() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      state = state.copyWith(status: ScanStatus.idle, hasError: false);
    }
  }

  String _parseError(Exception e) {
    final str = e.toString();
    if (str.contains('400')) return 'Đơn hàng không hợp lệ hoặc sai trạng thái.';
    if (str.contains('403')) return 'Đơn hàng này không thuộc bưu cục của bạn.';
    if (str.contains('404')) return 'Không tìm thấy đơn hàng với mã này.';
    if (str.contains('SocketException')) return 'Mất kết nối mạng.';
    return 'Lỗi không xác định. Thử lại sau.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final stationProvider =
    StateNotifierProvider.autoDispose<StationNotifier, StationState>((ref) {
  return StationNotifier(ref.read(stationRepositoryProvider));
});
