import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/ticket_repository.dart';

class TicketState {
  final String? imagePath;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const TicketState({
    this.imagePath,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  TicketState copyWith({
    String? imagePath,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool clearImage = false,
  }) {
    return TicketState(
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class TicketNotifier extends StateNotifier<TicketState> {
  final TicketRepository _repository;

  TicketNotifier(this._repository) : super(const TicketState());

  /// Lưu đường dẫn ảnh chứng minh được chọn
  void setImagePath(String? path) {
    state = state.copyWith(imagePath: path);
  }

  /// Gỡ bỏ hình ảnh đang chọn
  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  /// Gửi báo cáo sự cố (Ticket) lên server
  Future<bool> submitTicket({
    required String orderId,
    required String issueType,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      await _repository.createTicket(
        orderId: orderId,
        issueType: issueType,
        description: description,
        imagePath: state.imagePath,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      String msg = 'Đã xảy ra lỗi khi báo cáo sự cố.';
      final errStr = e.toString();
      if (errStr.contains('404')) {
        msg = 'Không tìm thấy đơn hàng này trong hệ thống!';
      } else if (errStr.contains('SocketException')) {
        msg = 'Lỗi kết nối mạng, vui lòng thử lại.';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  /// Reset trạng thái
  void reset() {
    state = const TicketState();
  }
}

/// Provider tự động huỷ (auto-dispose) để dọn sạch form khi thoát màn hình
final ticketProvider = StateNotifierProvider.autoDispose<TicketNotifier, TicketState>((ref) {
  return TicketNotifier(ref.read(ticketRepositoryProvider));
});
