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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService().getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return const LoginScreen();
        }

        final role = snapshot.data!;
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
