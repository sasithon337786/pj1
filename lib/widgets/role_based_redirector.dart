// lib/widgets/role_based_redirector.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/login.dart'; // ถ้าใช้ LoginScreen จากไฟล์อื่น ให้แก้ import ตามที่โปรเจกต์ใช้จริง
import 'package:pj1/services/auth_service.dart';
import 'package:pj1/widgets/loading_screen.dart';

/// พาเลตสีตามธีมของหนู
class _AppColors {
  static const rose = Color(0xFFC98993);
  static const cream = Color(0xFFE6D2CD);
  static const mocha = Color(0xFF564843);
}

class RoleBasedRedirector extends StatefulWidget {
  const RoleBasedRedirector({super.key});

  @override
  State<RoleBasedRedirector> createState() => _RoleBasedRedirectorState();
}

class _RoleBasedRedirectorState extends State<RoleBasedRedirector> {
  bool _blockedDialogShown = false;

  /// === Dialog สไตล์ของหนู (cream + badge + ปุ่ม mocha + Kanit) ===
  Future<void> _showBlockedDialog(
      BuildContext context, AuthBlockedException error) async {
    if (!mounted) return;

    final st = (error.status.isNotEmpty ? error.status : 'unknown')
        .trim()
        .toLowerCase();
    final isSuspended = st == 'suspend' || st == 'suspended';
    final isDeleted = st == 'deleted';

    final title = 'ไม่สามารถเข้าสู่ระบบได้';
    final content = isDeleted
        ? 'คุณเข้าสู่ระบบไม่ได้เนื่องจากบัญชีของคุณถูกลบ'
        : isSuspended
            ? 'คุณเข้าสู่ระบบไม่ได้เนื่องจากบัญชีถูกระงับการใช้งาน'
            : (error.message.trim().isNotEmpty
                ? error.message.trim()
                : 'คุณไม่สามารถเข้าสู่ระบบได้ (สถานะ: ${error.status})');

    final iconData =
        isDeleted ? Icons.delete_forever_rounded : Icons.block_rounded;

    // ใช้ root navigator ให้ชัวร์ (กัน context ที่ไม่อยู่ใต้ Navigator)
    final nav = Navigator.maybeOf(context, rootNavigator: true);
    if (nav == null) return;
    final rootCtx = nav.context;

    await showGeneralDialog(
      context: rootCtx,
      barrierDismissible: true,
      barrierLabel: 'blocked-dialog',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim, __, ___) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: Opacity(
            opacity: curved.value,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  // คงสัดส่วนเดิม แต่ล็อกช่วงกว้างให้ดูดีทุกขนาดจอ
                  width: (MediaQuery.of(dialogCtx).size.width * 0.82)
                      .clamp(260.0, 460.0),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  decoration: BoxDecoration(
                    color: _AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 18,
                          offset: Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge ไอคอนวงกลม
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _AppColors.rose.withOpacity(0.20),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(iconData, size: 34, color: _AppColors.mocha),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kanit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.mocha,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // เนื้อหา
                      Text(
                        content,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _AppColors.mocha.withOpacity(0.85),
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ปุ่มปิด (ทึบสี mocha)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.maybeOf(dialogCtx, rootNavigator: true)
                                  ?.pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              backgroundColor: _AppColors.mocha,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              textStyle: GoogleFonts.kanit(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            child: Text(
                              'ปิด',
                              style: GoogleFonts.kanit(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// นัดเปิด dialog หลังเฟรมเพื่อหลบ navigator lock และกันเรียกซ้ำ
  void _scheduleBlockedDialog(BuildContext context, AuthBlockedException e) {
    if (_blockedDialogShown) return;
    _blockedDialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // เผื่อ route ยังไม่ active
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        await Future.delayed(const Duration(milliseconds: 16));
      }

      await _showBlockedDialog(context, e);

      if (mounted) {
        setState(() {
          _blockedDialogShown = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService().getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // ถ้า backend โยน AuthBlockedException มา: แสดง LoginScreen พร้อมเด้ง dialog หลังเฟรม
        if (snapshot.hasError) {
          final err = snapshot.error;
          if (err is AuthBlockedException) {
            _scheduleBlockedDialog(context, err);
          }
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
