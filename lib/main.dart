import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/add.dart';
import 'package:pj1/login.dart';
import 'package:pj1/mains.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    print('UID: ${user.uid}');
  }

  runApp(const MyApp());
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
          : const MainHomeScreen(), // <-- เช็คสถานะผู้ใช้ตรงนี้
    );
  }
}
