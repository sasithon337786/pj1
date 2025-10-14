import 'package:flutter/material.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/add.dart';
import 'package:pj1/login.dart';
import 'package:pj1/mains.dart';
// import 'package:pj1/login.dart';

import 'package:pj1/services/auth_service.dart';
import 'package:pj1/services/notification_service.dart';
import 'package:pj1/widgets/loading_screen.dart';

class RoleBasedRedirector extends StatelessWidget {
  const RoleBasedRedirector({super.key});

  Future<void> _setupNotifications() async {
    try {
      final idToken = await AuthService.getIdToken(); // สมมติ AuthService มีเมธอดนี้
      if (idToken != null && idToken.isNotEmpty) {
        debugPrint("🔔 เริ่มตั้งเวลาแจ้งเตือนจาก RoleBasedRedirector...");
        await NotificationService.scheduleReminders(idToken);
        debugPrint("✅ การแจ้งเตือนถูกตั้งค่าเรียบร้อย");
      } else {
        debugPrint("⚠️ ไม่มี idToken, ข้ามการตั้งแจ้งเตือน");
      }
    } catch (e) {
      debugPrint("❌ เกิดข้อผิดพลาดในการตั้งแจ้งเตือน: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService().getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          debugPrint("🔴 Role not found → go to LoginScreen");
          return const LoginScreen();
        }

        final role = snapshot.data!;
        debugPrint("🟢 User role detected: $role");

        // ✅ เรียก setup แจ้งเตือนเมื่อเจอ role
        _setupNotifications();

        switch (role) {
          case 'admin':
            return const MainAdmin();
          case 'member':
            return const HomePage();
          default:
            debugPrint("⚠️ Unknown role: $role → go to LoginScreen");
            return const LoginScreen();
        }
      },
    );
  }
}
