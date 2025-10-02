import 'userModel.dart';

class AuthResponse {
  final UserModel user;
  final String token;

  AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? json; // ถ้าไม่มี key 'user' ใช้ json ตรงๆ
    return AuthResponse(
      user: UserModel.fromJson(userJson),
      token: json['token'] ?? '',
    );
  }
}
