import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/add.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final idToken = await user.getIdToken(true);
    // print('ID Token: $idToken');
    // print('UID: ${user.uid}');
  }

  runApp(const MyApp());
}

class RoleBasedRedirector extends StatelessWidget {
  const RoleBasedRedirector({super.key});

  Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // ขอ idToken ใหม่เสมอ
    final idToken = await user.getIdToken(true);

    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/api/auth/getProfile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['role'] as String?;
    }

    // ถ้า token ใช้ไม่ได้แล้ว ให้เซ็นเอาท์แล้วให้กลับไปล็อกอินใหม่
    if (response.statusCode == 401 || response.statusCode == 403) {
      await FirebaseAuth.instance.signOut();
      return null;
    }

    debugPrint('getProfile error: ${response.statusCode} ${response.body}');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          // ถ้า null (เช่น signOut ไปแล้วเพราะ token หมดอายุ) → กลับหน้า Login
          return const LoginScreen();
        }

        final role = snapshot.data;
        if (role == 'admin') {
          return const MainAdmin(); // admin
        } else {
          return const MainHomeScreen(); // member หรืออื่น ๆ
        }
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // ✅ ใช้สตรีมเช็คสถานะล็อกอินแบบเรียลไทม์
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // ยังไม่ล็อกอิน → ไปหน้า Login
          if (!snap.hasData) {
            return const LoginScreen();
          }
          // ล็อกอินแล้ว → เช็ค role เพื่อเด้งไป admin หรือ user
          return const RoleBasedRedirector();
        },
      ),
    );
  }
}
