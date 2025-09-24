import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constant/api_endpoint.dart';
import '../models/auth_response.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Static getters for easy access
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

  /// Sign in with email and password
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

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(jsonDecode(response.body));
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Server rejected token';
        throw Exception(error);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in aborted by user');
      }

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

      final idToken = await user.getIdToken();
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

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(jsonDecode(response.body));
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Server rejected token';
        throw Exception(error);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      rethrow;
    }
  }

  /// Get user role from backend
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

      if (response.statusCode == 401 || response.statusCode == 403) {
        // await signOut();
        return null;
      }

      throw Exception('Failed to get user role: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String birthday,
    File? image,
  }) async {
    try {
      final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/auth/registerwithemailpassword');
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

  /// Sign out user
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      // Handle sign out errors if needed
      rethrow;
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get Firebase error message in Thai
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
