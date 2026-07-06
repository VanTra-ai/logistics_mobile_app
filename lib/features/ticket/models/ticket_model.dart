/// Model đại diện cho Yêu cầu sự cố/Khiếu nại (Ticket)
class TicketModel {
  final String id;
  final String issueType;
  final String description;
  final List<String> evidenceImages;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;

  const TicketModel({
    required this.id,
    required this.issueType,
    required this.description,
    required this.evidenceImages,
    required this.status,
    this.adminResponse,
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      issueType: json['issue_type'] as String? ?? json['issueType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      evidenceImages: json['evidence_images'] != null
          ? List<String>.from(json['evidence_images'] as Iterable)
          : (json['evidenceImages'] != null ? List<String>.from(json['evidenceImages'] as Iterable) : const []),
      status: json['status'] as String? ?? 'OPEN',
      adminResponse: json['admin_response'] as String? ?? json['adminResponse'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_type': issueType,
      'description': description,
      'evidence_images': evidenceImages,
      'status': status,
      'admin_response': adminResponse,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
