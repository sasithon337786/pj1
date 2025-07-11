class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl; 
  final String role;
  final String status; 
  final DateTime? birthday; 

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    required this.role,
    required this.status,
    this.birthday,
  });


  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      photoUrl: json['photo_url'] as String?, 
      role: json['role'] as String,
      status: json['status'] as String,
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photo_url': photoUrl,
      'role': role,
      'status': status,
      'birthday': birthday?.toIso8601String().split('T')[0], 
    };
  }
}