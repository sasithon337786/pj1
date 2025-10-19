// lib/models/auth_response.dart
class AuthResponse {
  final String message;
  final String uid;
  final String role;
  final String token;
  final String? birthday;
  final String? status; // 'active' | 'suspend' | 'deleted'

  AuthResponse({
    required this.message,
    required this.uid,
    required this.role,
    required this.token,
    this.birthday,
    this.status,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
     role: (json['role'] as String?)?.toLowerCase() ?? 'member',
      token: json['token'] as String? ?? '',
      birthday: json['birthday'] as String?,
      status: (json['status'] as String?)?.toLowerCase() ?? 'active',
    );
  }
  bool get isActive => status == 'active';
}
