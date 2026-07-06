import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  final Dio _dio;

  const TicketRepository(this._dio);

  /// Tạo sự cố mới (báo cáo Ticket) gửi lên NestJS
  Future<TicketModel> createTicket({
    required String orderId,
    required String issueType,
    required String description,
    required String? imagePath,
  }) async {
    // Chuẩn bị FormData theo yêu cầu Content-Type: multipart/form-data
    final formData = FormData.fromMap({
      'orderId': orderId.trim(),
      'issueType': issueType,
      'description': description.trim(),
      if (imagePath != null)
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/tickets',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final data = response.data?['data'] ?? response.data ?? {};
    return TicketModel.fromJson(data as Map<String, dynamic>);
  }
}

/// Provider cho TicketRepository
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(ref.read(dioProvider));
});
