/// Model đại diện cho thông tin người dùng trả về từ Backend.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
    };
  }

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, fullName: $fullName, role: $role)';
}
