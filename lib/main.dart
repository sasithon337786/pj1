import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pj1/login.dart';
import 'package:pj1/services/notification_service.dart';
import 'package:pj1/widgets/loading_screen.dart';
import 'package:pj1/widgets/role_based_redirector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ ต้อง init NotificationService ก่อน runApp()
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }

          if (!snap.hasData) {
            debugPrint("🔴 No user found → go to LoginScreen");
            return const LoginScreen();
          }

          debugPrint(
              "🟢 User logged in: ${snap.data!.uid} → go to RoleBasedRedirector");
          return const RoleBasedRedirector();
        },
      ),
    );
  }
}
