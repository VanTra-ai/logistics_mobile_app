/// Model bưu cục (Hub)
class HubModel {
  final String id;
  final String name;
  final String? address;

  const HubModel({
    required this.id,
    required this.name,
    this.address,
  });

  factory HubModel.fromJson(Map<String, dynamic> json) {
    return HubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }

  @override
  String toString() => 'HubModel(id: $id, name: $name, address: $address)';
}

/// Model đại diện cho thông tin người dùng trả về từ Backend.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final HubModel? hub;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.hub,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      hub: json['hub'] != null
          ? HubModel.fromJson(json['hub'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'hub': hub?.toJson(),
    };
  }

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, fullName: $fullName, role: $role, hub: $hub)';
}
