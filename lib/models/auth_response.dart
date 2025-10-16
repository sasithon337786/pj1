class AuthResponse {
  final String message;
  final String uid;
  final String role;
  final String token;
  final String? birthday;

  AuthResponse({
    required this.message,
    required this.uid,
    required this.role,
    required this.token,
    this.birthday,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
  return AuthResponse(
    message: json['message'] as String? ?? '',
    uid: json['uid'] as String? ?? '',
    role: json['role'] as String? ?? 'member', // ใช้ default ถ้า null
    token: json['token'] as String? ?? '',
    birthday: json['birthday'] as String?,
  );
}
}
