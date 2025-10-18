// lib/widgets/role_based_redirector.dart
import 'package:flutter/material.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/login.dart';
import 'package:pj1/services/auth_service.dart';
import 'package:pj1/widgets/loading_screen.dart';

class RoleBasedRedirector extends StatelessWidget {
  const RoleBasedRedirector({super.key});

  Future<void> _maybeShowBlockedDialog(BuildContext context, Object? error) async {
    if (error is AuthBlockedException) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('ไม่สามารถเข้าสู่ระบบได้'),
            content: Text(
              (error.status == 'deleted')
                  ? 'คุณเข้าสู่ระบบไม่ได้เนื่องจากบัญชีของคุณถูกลบ'
                  : (error.status == 'suspend' || error.status == 'suspended')
                      ? 'คุณเข้าสู่ระบบไม่ได้เนื่องจากบัญชีถูกระงับการใช้งาน'
                      : (error.message.isNotEmpty ? error.message : 'คุณเข้าสู่ระบบไม่ได้ (สถานะ: ${error.status})'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ปิด')),
            ],
          ),
        );
      });
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

        // ✅ ใช้ ?. ไม่ใช้ !
        if (snapshot.hasError) {
          _maybeShowBlockedDialog(context, snapshot.error);
          return const LoginScreen();
        }

        final role = snapshot.data;
        if (role == null || role.isEmpty) {
          return const LoginScreen();
        }

        switch (role) {
          case 'admin':
            return const MainAdmin();
          case 'member':
            return const HomePage();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
