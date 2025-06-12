import 'package:flutter/material.dart';
import 'package:pj1/Addmin/deteil_user_admin.dart';
import 'package:pj1/Addmin/list_admin.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/Services/ApiService.dart';
import 'package:pj1/Time_Activity.dart';
import 'package:pj1/add.dart';
import 'package:pj1/add_expectations.dart';
import 'package:pj1/chooseactivity.dart';
import 'package:pj1/custom_Activity.dart';
import 'package:pj1/doing_activity.dart';
import 'package:pj1/lifestly_Activity.dart';
import 'package:pj1/login.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/registration_screen.dart';
import 'package:pj1/set_time.dart';
import 'package:pj1/sport_Activity.dart';
import 'package:pj1/target.dart';
import 'package:pj1/user_Graph.dart';
import 'package:pj1/user_expectations.dart';
import 'package:pj1/user_grapline.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  final api = ApiService();
  api.checkStatus(); // เรียกตอนเริ่มแอป
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
        home: ListuserSuspended());
  }
}
