// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constant/api_endpoint.dart';
import '../models/auth_response.dart';

/// Exception สำหรับกรณีที่สถานะผู้ใช้ไม่ใช่ 'active'
/// Exception สำหรับกรณีที่สถานะผู้ใช้ไม่ใช่ 'active'
class AuthBlockedException implements Exception {
  final String status; // 'suspended' | 'deleted' | อื่น ๆ
  final String message; // ข้อความจาก backend (ถ้ามี)
  AuthBlockedException(this.status, this.message);
  @override
  String toString() => 'AuthBlockedException($status): $message';
}

/// แปลงสถานะให้เป็นรูปแบบมาตรฐาน (กันเคส backend/DB เก่าเขียน 'suspend')
String _normalizeStatus(String? status) {
  final st = (status ?? '').toLowerCase().trim();
  if (st == 'suspend') return 'suspended';
  return st;
}

/// โยน exception พร้อมข้อความภาษาไทย
Never _throwBlocked(String? status, String? serverMessage) {
  final st = _normalizeStatus(status);
  final msg = (serverMessage ?? '').trim();

  if (st == 'suspended') {
    throw AuthBlockedException(
      st,
      msg.isNotEmpty
          ? msg
          : 'คุณไม่สามารถเข้าสู่ระบบได้เนื่องจากบัญชีถูกระงับการใช้งาน',
    );
  }
  if (st == 'deleted') {
    throw AuthBlockedException(
      st,
      msg.isNotEmpty
          ? msg
          : 'คุณไม่สามารถเข้าสู่ระบบได้เนื่องจากบัญชีของคุณถูกลบ',
    );
  }
  throw AuthBlockedException(
    st,
    msg.isNotEmpty ? msg : 'คุณไม่สามารถเข้าสู่ระบบได้ (สถานะ: $status)',
  );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Static getters
  static User? get currentUser => FirebaseAuth.instance.currentUser;
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get Firebase ID Token
  static Future<String?> getIdToken({bool forceRefresh = true}) async {
    return await FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);
  }

  /// Get authenticated headers for API requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final idToken = await getIdToken(forceRefresh: true);
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  // ------------------------------------------------------------
  // Email/Password Sign-in
  // ------------------------------------------------------------
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to authenticate user');

      final idToken = await user.getIdToken(true);
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/loginwithemail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(body);
        final status = _normalizeStatus(auth.status);

        // ✅ อนุญาตเฉพาะ active
        if (status != 'active') {
          await _auth.signOut();
          try {
            await _googleSignIn.signOut();
          } catch (_) {}
          _throwBlocked(status, body['message'] as String?);
        }

        return auth;
      } else {
        // ❌ 403/410 จะมาที่นี่
        await _auth.signOut();
        try {
          await _googleSignIn.signOut();
        } catch (_) {}

        String? status;
        String? message;
        try {
          final err = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          status = err['status'] as String?;
          message = err['message'] as String?;
        } catch (_) {
          message = 'เข้าสู่ระบบล้มเหลว (HTTP ${response.statusCode})';
        }

        _throwBlocked(status, message);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      // 1) ล้างเซสชันเก่าของ Google Play Services ก่อนเสมอ
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // 2) เปิดตัวเลือกบัญชีทุกครั้ง
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in aborted by user');
      }

      // 3) แลก credential กับ Firebase
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // 4) ดึง Firebase ID Token สดใหม่เสมอ
      final idToken = await user.getIdToken(true);

      // 5) เรียก backend
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/loginwithgoogle'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        }),
      );

      // 6) พาร์ส body ให้ปลอดภัย
      Map<String, dynamic> body = {};
      try {
        if (response.body.isNotEmpty) {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {
        // ถ้าพาร์สไม่ได้ ปล่อยเป็น {} ไป
      }

      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(body);
        final status = _normalizeStatus(auth.status);

        // ✅ อนุญาตเฉพาะ active
        if (status != 'active') {
          await _auth.signOut();
          try {
            await _googleSignIn.signOut();
          } catch (_) {}
          _throwBlocked(status, body['message'] as String?);
        }

        return auth;
      }

      // ❌ สถานะอื่น ๆ: ออกจากระบบฝั่งไคลเอนต์ แล้วโยนสาเหตุแบบสวยงาม
      await _auth.signOut();
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      String? status = body['status'] as String?;
      String? message = body['message'] as String?;
      if (status == null && message == null) {
        message = 'เข้าสู่ระบบล้มเหลว (HTTP ${response.statusCode})';
      }
      _throwBlocked(status, message); // จะ throw AuthBlockedException
    } on FirebaseAuthException catch (e) {
      // แปลงโค้ด Firebase เป็นข้อความไทย
      throw Exception(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // Get user role from backend
  // ------------------------------------------------------------
  Future<String?> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final idToken = await user.getIdToken(true);
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/getProfile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'] as String?;
      }

      // ✅ ถ้า backend ส่ง 401/403 และมี status ใน body → โยน AuthBlockedException
      if (response.statusCode == 401 || response.statusCode == 403) {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final status = (body['status'] ?? '').toString();
        final message = (body['message'] ?? '').toString();
        if (status.isNotEmpty) {
          _throwBlocked(status, message); // <-- จะ throw AuthBlockedException
        }
        return null; // ถ้าไม่มี status ก็คืน null ไปเหมือนเดิม
      }

      throw Exception('Failed to get user role: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // Register new user
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String birthday,
    File? image,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/auth/registerwithemailpassword',
      );
      final request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'username': name,
        'email': email,
        'password': password,
        'birthday': birthday,
      });

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profileImage',
            image.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      return {
        'status': response.statusCode,
        'body': data,
      };
    } catch (e) {
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // Sign out
  // ------------------------------------------------------------
  Future<void> signOut() async {
    try {
      // พยายาม revoke การเชื่อมต่อบัญชี Google (ล้าง chooser cache)
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        // เงียบได้: ถ้าไม่ได้เคยเชื่อม Google หรือบนบางเครื่อง method นี้จะ throw
      }

      // เผื่อกรณียังมี session ค้าง ให้ signOut อีกรอบ
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // ออกจาก Firebase เสมอ
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // Misc
  // ------------------------------------------------------------
  bool get isSignedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'ไม่พบผู้ใช้งานนี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-email':
        return 'อีเมลไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกปิดใช้งาน';
      case 'too-many-requests':
        return 'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณาลองใหม่ภายหลัง';
      case 'operation-not-allowed':
        return 'การเข้าสู่ระบบด้วยวิธีนี้ไม่ได้รับอนุญาต';
      case 'weak-password':
        return 'รหัสผ่านไม่ปลอดภัย';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      default:
        return 'เกิดข้อผิดพลาด: $errorCode';
    }
  }
}
