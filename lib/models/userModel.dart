// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl; // สามารถเป็น null ได้
  final String role; // 'member', 'admin'
  final String status; // 'active', 'suspended', 'deleted'
  final DateTime? birthday; // สามารถเป็น null ได้

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    required this.role,
    required this.status,
    this.birthday,
  });

  // Factory constructor สำหรับสร้าง UserModel จาก JSON (Map)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      photoUrl: json['photo_url'] as String?, // ใช้ as String? เพื่อรองรับ null
      role: json['role'] as String,
      status: json['status'] as String,
      birthday: json['birthday'] != null // ตรวจสอบ null ก่อนแปลง
          ? DateTime.tryParse(json['birthday'] as String) // แปลง String วันที่เป็น DateTime
          : null,
    );
  }

  // (Optional) Method สำหรับแปลง UserModel กลับเป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photo_url': photoUrl,
      'role': role,
      'status': status,
      'birthday': birthday?.toIso8601String().split('T')[0], // แปลง DateTime กลับเป็น String 'YYYY-MM-DD'
    };
  }
}