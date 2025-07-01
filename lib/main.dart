import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/login.dart';
import 'package:pj1/mains.dart';

void main() async {
  // <--- ต้องมี async ด้วยนะคะ
  WidgetsFlutterBinding.ensureInitialized(); // <--- บรรทัดนี้
  await Firebase.initializeApp(); // <--- และบรรทัดนี้
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
        home: LoginScreen());
  }
}
