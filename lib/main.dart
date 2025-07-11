import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/add.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/login.dart';
import 'package:pj1/mains.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // final uid = FirebaseAuth.instance.currentUser?.uid;
  // print('UID: $uid');
  runApp(const MyApp());
}

class RoleBasedRedirector extends StatelessWidget {
  const RoleBasedRedirector({super.key});
  Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // ขอ idToken แบบรีเฟรชใหม่เสมอ (forceRefresh = true)
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
      return data['role']; // ได้ role จาก backend
    } else {
      print('Error: ${response.body}');
      return null;
    }
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
          return const Scaffold(
            body: Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้')),
          );
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
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginScreen()
          : const RoleBasedRedirector(), // ✅ เปลี่ยนให้ไปเช็ค role
    );
  }
}
