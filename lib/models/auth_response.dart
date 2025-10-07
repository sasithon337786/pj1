class AuthResponse {
  final String message;
  final String uid;
  final String role;
  final String token;

  AuthResponse({
    required this.message,
    required this.uid,
    required this.role,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String,
      uid: json['uid'] as String,
      role: json['role'] as String,  // ❌ ใช้ as String? ถ้า backend อาจส่ง null
      token: json['token'] as String,
    );
  }
}
