// lib/screens/account_page.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/login.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/models/userModel.dart';
import 'package:pj1/services/auth_service.dart';
import 'package:pj1/target.dart';
import 'package:pj1/add.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 3;
  UserModel? user;
  bool isLoading = true;

  // Theme
  final Color _bg = const Color(0xFFC98993);
  final Color _appBar = const Color(0xFF564843);
  final Color _card = const Color(0xFFEFEAE3);
  final Color _pill = const Color(0xFFE6D2CD);
  final Color _accent = const Color(0xFFC98993);

  bool _isLoggingOut = false;

  // ====== Helpers ======
  // บีบ DateTime ให้เป็น date-only (ตัดผลกระทบ timezone/เวลาออก)
  DateTime _toDateOnly(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  // ---------- Logout ----------
  Future<void> _confirmAndLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _card,
          title: Text('ยืนยันการออกจากระบบ',
              style: GoogleFonts.kanit(
                  color: _appBar, fontWeight: FontWeight.w600)),
          content: Text('แน่ใจหรือไม่ว่าจะออกจากระบบตอนนี้?',
              style: GoogleFonts.kanit(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('ยกเลิก', style: GoogleFonts.kanit(color: _accent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _appBar,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child:
                  Text('ยืนยัน', style: GoogleFonts.kanit(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoggingOut = true);
    try {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Widget _buildLogoutButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOutCubic,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isLoggingOut
              ? [Colors.red.shade300, Colors.red.shade400]
              : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))
        ],
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoggingOut ? null : _confirmAndLogout,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoggingOut) ...[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  const Icon(Icons.logout_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  _isLoggingOut ? 'กำลังออกจากระบบ...' : 'ออกจากระบบ',
                  style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Dialog: เตือนต้องใส่เหตุผล ----------
  Future<void> _showReasonRequiredDialog() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'reason-required',
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
                  width: (MediaQuery.of(dialogCtx).size.width * 0.82)
                      .clamp(260.0, 460.0),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 18,
                          offset: Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: _accent.withOpacity(0.20),
                            shape: BoxShape.circle),
                        child:
                            Icon(Icons.info_rounded, size: 34, color: _appBar),
                      ),
                      const SizedBox(height: 14),
                      Text('กรุณาใส่เหตุผล',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kanit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _appBar)),
                      const SizedBox(height: 8),
                      Text('คุณต้องใส่เหตุผลในการส่งคำร้องด้วยค่ะ',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kanit(
                              fontSize: 16,
                              color: _appBar.withOpacity(0.85),
                              height: 1.35,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () =>
                            Navigator.maybeOf(dialogCtx, rootNavigator: true)
                                ?.pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          backgroundColor: _appBar,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          textStyle: GoogleFonts.kanit(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        child: Text('ปิด',
                            style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
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

  // ---------- Edit Profile + Change Password ----------
  void _openEditProfileDialog() {
    // ตรวจ provider: แก้รหัสผ่านได้เฉพาะ email/password
    final fbUser = FirebaseAuth.instance.currentUser;
    final bool canChangePassword =
        fbUser?.providerData.any((p) => p.providerId == 'password') ?? false;

    // ฟิลด์โปรไฟล์
    final nameCtrl = TextEditingController(text: user?.username ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final bdayCtrl = TextEditingController(
      text: user?.birthday != null
          ? DateFormat('dd/MM/yyyy').format(_toDateOnly(user!.birthday!))
          : '',
    );

    // ฟิลด์รหัสผ่าน (ใช้เฉพาะเมื่อ canChangePassword)
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool changePassword = false;
    bool ob1 = true, ob2 = true, ob3 = true;
    final formKey = GlobalKey<FormState>();

    String? _required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'กรุณากรอกข้อมูล' : null;

    String? _email(String? v) {
      if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
      return ok ? null : 'อีเมลไม่ถูกต้อง';
    }

    String? _newPassValidator(String? v) {
      if (!changePassword || !canChangePassword) return null;
      if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่านใหม่';
      if (v.length < 8) return 'รหัสผ่านใหม่ต้องยาวอย่างน้อย 8 ตัวอักษร';
      return null;
    }

    String? _confirmPassValidator(String? v) {
      if (!changePassword || !canChangePassword) return null;
      if (v == null || v.isEmpty) return 'กรุณายืนยันรหัสผ่านใหม่';
      if (v != newPassCtrl.text) return 'รหัสผ่านใหม่กับการยืนยันไม่ตรงกัน';
      return null;
    }

    Future<void> _pickBirthday(StateSetter setDState) async {
      final now = DateTime.now();
      final initial = user?.birthday != null
          ? _toDateOnly(user!.birthday!)
          : DateTime(now.year - 18, now.month, now.day);
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: now,
        helpText: 'เลือกวันเกิด',
        cancelText: 'ยกเลิก',
        confirmText: 'ยืนยัน',
      );
      if (picked != null) {
        // บีบเป็น date-only อีกชั้นให้ชัวร์
        final only = _toDateOnly(picked);
        bdayCtrl.text = DateFormat('dd/MM/yyyy').format(only);
        setDState(() {});
      }
    }

    InputDecoration _dec(String hint, {Widget? suffix}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.kanit(color: Colors.black38),
        filled: true,
        fillColor: _pill.withOpacity(0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        suffixIcon: suffix,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool saving = false;

        return StatefulBuilder(
          builder: (ctx, setDState) {
            Future<void> _submit() async {
              if (!formKey.currentState!.validate()) return;
              setDState(() => saving = true);

              try {
                // 1) อัปเดตโปรไฟล์ที่ backend (ส่งวันเกิดเป็น yyyy-MM-dd)
                final idToken =
                    await FirebaseAuth.instance.currentUser!.getIdToken();
                final String? birthdayPayload = bdayCtrl.text.trim().isEmpty
                    ? null
                    : DateFormat('yyyy-MM-dd').format(
                        DateFormat('dd/MM/yyyy')
                            .parseStrict(bdayCtrl.text.trim()),
                      );

                final resp = await http.put(
                  Uri.parse('${ApiEndpoints.baseUrl}/api/users/edit'),
                  headers: {
                    'Authorization': 'Bearer $idToken',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'username': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'birthday': birthdayPayload,
                  }),
                );

                final Map<String, dynamic> body =
                    (resp.body.isNotEmpty) ? jsonDecode(resp.body) : {};
                final ok = resp.statusCode == 200 &&
                    (body['success'] == true || body['message'] != null);

                if (!ok) {
                  final msg = body['message']?.toString() ??
                      'อัปเดตไม่สำเร็จ (HTTP ${resp.statusCode})';
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  }
                  return;
                }

                // 2) เปลี่ยนรหัสผ่าน (เฉพาะ email/password เท่านั้น และติ๊กสวิตช์)
                if (canChangePassword && changePassword) {
                  final fbUser = FirebaseAuth.instance.currentUser;
                  if (fbUser == null) throw 'ไม่พบผู้ใช้ปัจจุบัน';

                  final emailForAuth = emailCtrl.text.trim().isNotEmpty
                      ? emailCtrl.text.trim()
                      : (fbUser.email ?? '');

                  final cred = EmailAuthProvider.credential(
                    email: emailForAuth,
                    password: currentPassCtrl.text,
                  );

                  try {
                    await fbUser.reauthenticateWithCredential(cred);
                    await fbUser.updatePassword(newPassCtrl.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('เปลี่ยนรหัสผ่านเรียบร้อย')),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String msg = 'เปลี่ยนรหัสผ่านไม่สำเร็จ: ${e.code}';
                    if (e.code == 'wrong-password') {
                      msg = 'รหัสผ่านเดิมไม่ถูกต้อง';
                    } else if (e.code == 'requires-recent-login') {
                      msg = 'กรุณาล็อกอินใหม่อีกครั้งเพื่อความปลอดภัย';
                    } else if (e.code == 'weak-password') {
                      msg = 'รหัสผ่านใหม่อ่อนเกินไป';
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                    }
                  }
                }

                // 3) โหลดโปรไฟล์ล่าสุด + ปิด dialog
                await _loadUserProfile();
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('อัปเดตข้อมูลเรียบร้อย')),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('อัปเดตไม่สำเร็จ: $e')),
                  );
                }
              } finally {
                setDState(() => saving = false);
              }
            }

            return AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('แก้ไขข้อมูลส่วนตัว',
                      style: GoogleFonts.kanit(
                          color: _appBar,
                          fontWeight: FontWeight.w700,
                          fontSize: 20)),
                  const SizedBox(height: 6),
                  Container(height: 2, color: _appBar.withOpacity(0.5)),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        validator: _required,
                        style: GoogleFonts.kanit(),
                        decoration: _dec('ชื่อ'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailCtrl,
                        validator: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.kanit(),
                        decoration: _dec('อีเมล'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: bdayCtrl,
                        readOnly: true,
                        onTap: () => _pickBirthday(setDState),
                        validator: _required,
                        style: GoogleFonts.kanit(),
                        decoration: _dec('วันเกิด (วัน/เดือน/ปี)',
                            suffix: const Icon(Icons.calendar_today)),
                      ),
                      const SizedBox(height: 18),

                      // เฉพาะผู้ใช้ email/password เท่านั้นที่เห็นส่วนเปลี่ยนรหัสผ่าน
                      if (canChangePassword) ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('ต้องการเปลี่ยนรหัสผ่าน',
                              style: GoogleFonts.kanit(
                                  fontWeight: FontWeight.w600)),
                          value: changePassword,
                          onChanged: (v) => setDState(() => changePassword = v),
                        ),
                        if (changePassword) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: currentPassCtrl,
                            obscureText: ob1,
                            validator: (v) {
                              if (!changePassword) return null;
                              if (v == null || v.isEmpty)
                                return 'กรุณากรอกรหัสผ่านเดิม';
                              return null;
                            },
                            style: GoogleFonts.kanit(),
                            decoration: _dec(
                              'รหัสผ่านเดิม',
                              suffix: IconButton(
                                icon: Icon(ob1
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setDState(() => ob1 = !ob1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: newPassCtrl,
                            obscureText: ob2,
                            validator: _newPassValidator,
                            style: GoogleFonts.kanit(),
                            decoration: _dec(
                              'รหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร)',
                              suffix: IconButton(
                                icon: Icon(ob2
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setDState(() => ob2 = !ob2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: confirmPassCtrl,
                            obscureText: ob3,
                            validator: _confirmPassValidator,
                            style: GoogleFonts.kanit(),
                            decoration: _dec(
                              'ยืนยันรหัสผ่านใหม่',
                              suffix: IconButton(
                                icon: Icon(ob3
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setDState(() => ob3 = !ob3),
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        // Google sign-in: ซ่อนฟิลด์ทั้งหมด และขึ้นแจ้งสั้น ๆ
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _pill.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'คุณเข้าสู่ระบบด้วย Google จึงไม่ต้องตั้งรหัสผ่านในระบบนี้',
                            style: GoogleFonts.kanit(color: Colors.black87),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child:
                      Text('ยกเลิก', style: GoogleFonts.kanit(color: _accent)),
                ),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appBar,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('ยืนยัน',
                            style: GoogleFonts.kanit(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- ส่งคำร้อง (ลบบัญชี/ระงับบัญชี) ----------
  InputDecoration _dialogFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.kanit(color: Colors.black38),
      filled: true,
      fillColor: _pill.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  void _openPetitionDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController textCtrl = TextEditingController();
    String? type;
    bool sending = false;

    final Map<String, String> typeToStatus = {
      'ลบบัญชี': 'deleted',
      'ระงับบัญชี': 'suspended',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDState) {
            Future<void> submit() async {
              // ต้องเลือกประเภท
              if (!formKey.currentState!.validate()) return;
              if (type == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาเลือกประเภทคำร้อง')),
                );
                return;
              }

              // ต้องกรอกเหตุผล
              if (textCtrl.text.trim().isEmpty) {
                await _showReasonRequiredDialog();
                return;
              }

              final status = typeToStatus[type]!;
              setDState(() => sending = true);

              try {
                final fbUser = FirebaseAuth.instance.currentUser;
                if (fbUser == null) throw 'กรุณาเข้าสู่ระบบใหม่อีกครั้ง';
                final idToken = await fbUser.getIdToken(true);

                final resp = await http.post(
                  Uri.parse('${ApiEndpoints.baseUrl}/api/users/mystatus'),
                  headers: {
                    'Authorization': 'Bearer $idToken',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'status': status,
                    'reason': textCtrl.text.trim(),
                  }),
                );

                if (resp.statusCode == 200) {
                  await _loadUserProfile();
                  if (!mounted) return;

                  if (status == 'deleted') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ลบบัญชีสำเร็จ กำลังออกจากระบบ...'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await Future.delayed(const Duration(milliseconds: 800));
                    await AuthService().signOut();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                    return;
                  }

                  // suspended
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('ระงับบัญชีสำเร็จ'),
                        backgroundColor: Colors.green),
                  );
                } else {
                  String err = 'ดำเนินการไม่สำเร็จ (HTTP ${resp.statusCode})';
                  try {
                    final body = jsonDecode(resp.body);
                    if (body is Map && body['message'] != null) {
                      err = body['message'].toString();
                    }
                  } catch (_) {}
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('เกิดข้อผิดพลาด: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              } finally {
                setDState(() => sending = false);
              }
            }

            return AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('จัดการบัญชี',
                      style: GoogleFonts.kanit(
                          fontSize: 20,
                          color: _appBar,
                          fontWeight: FontWeight.w700)),
                  Container(
                      height: 2,
                      margin: const EdgeInsets.only(top: 6),
                      color: _appBar.withOpacity(0.5)),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: _dialogFieldDecoration('เลือกประเภท'),
                      icon: Icon(Icons.arrow_drop_down, color: _appBar),
                      style: GoogleFonts.kanit(color: Colors.black87),
                      items: const [
                        DropdownMenuItem(
                            value: 'ลบบัญชี', child: Text('ลบบัญชี')),
                        DropdownMenuItem(
                            value: 'ระงับบัญชี', child: Text('ระงับบัญชี')),
                      ],
                      onChanged: (v) => setDState(() => type = v),
                      validator: (v) => v == null ? 'กรุณาเลือกประเภท' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: textCtrl,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณาระบุเหตุผล'
                          : null,
                      decoration: _dialogFieldDecoration('เหตุผล (ต้องระบุ)'),
                      style: GoogleFonts.kanit(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(ctx),
                  child:
                      Text('ยกเลิก', style: GoogleFonts.kanit(color: _accent)),
                ),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appBar,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: sending ? null : submit,
                    child: sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('ยืนยัน',
                            style: GoogleFonts.kanit(
                                color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- Data ----------
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final fetchedUser = await fetchUserProfile();
    if (!mounted) return;
    setState(() {
      user = fetchedUser;
      isLoading = false;
    });
  }

  Future<UserModel?> fetchUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final idToken = await currentUser.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/getProfile'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        // ถ้าใน UserModel มีการ parse แบบใช้ DateTime.parse(...Z) แนะนำให้ปรับฝั่งโมเดลให้ date-only ตามแนวคิดเดียวกัน
        return UserModel.fromJson(jsonMap);
      } else {
        debugPrint("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
    return null;
  }

  // ---------- Nav ----------
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
        break;
      case 1:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const Targetpage()));
        break;
      case 2:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const Graphpage()));
        break;
      case 3:
        break;
    }
  }

  // ---------- UI helpers ----------
  Widget _chip(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _card),
            const SizedBox(width: 6),
          ],
          Text(text, style: GoogleFonts.kanit(fontSize: 13, color: _card)),
        ],
      ),
    );
  }

  Widget _infoTile(
      {required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
        ],
        border: Border.all(color: Colors.black12.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: _appBar.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _appBar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.kanit(fontSize: 15, color: Colors.black87),
                children: [
                  TextSpan(
                      text: '$label : ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(
                      text: value,
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(UserModel u) {
    final photo = u.photoUrl;
    final name = u.username;
    final mail = u.email;
    final role = u.role;
    final status = u.status;
    final bday = u.birthday != null
        ? DateFormat('dd MMM yyyy').format(_toDateOnly(u.birthday!))
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: _bg,
                backgroundImage: photo != null
                    ? NetworkImage(photo)
                    : const AssetImage('assets/images/boy.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kanit(
                            fontSize: 20,
                            color: _accent,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(mail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kanit(
                            fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(role, icon: Icons.workspace_premium),
                        _chip(status, icon: Icons.verified_user),
                        if (bday != null) _chip(bday, icon: Icons.cake),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openEditProfileDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appBar,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  label: Text('แก้ไขข้อมูลส่วนตัว',
                      style:
                          GoogleFonts.kanit(color: Colors.white, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openPetitionDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pill,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.person, size: 18, color: _appBar),
                  label: Text('ส่งคำร้อง',
                      style: GoogleFonts.kanit(color: _appBar, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userInfoSection(UserModel u) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ข้อมูลของฉัน',
              style: GoogleFonts.kanit(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _card)),
          const SizedBox(height: 12),
          _infoTile(
              icon: Icons.badge_outlined, label: 'Name', value: u.username),
          _infoTile(
              icon: Icons.alternate_email, label: 'Email', value: u.email),
          _infoTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Role',
              value: u.role),
          _infoTile(
              icon: Icons.verified_user_outlined,
              label: 'Status',
              value: u.status),
          if (u.birthday != null)
            _infoTile(
              icon: Icons.cake_outlined,
              label: 'Birthday',
              value: DateFormat('dd MMM yyyy').format(_toDateOnly(u.birthday!)),
            ),
        ],
      ),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: MediaQuery.of(context).padding.top + 70,
                color: _appBar,
                width: double.infinity,
              ),
              const SizedBox(height: 54),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : user == null
                        ? Center(
                            child: Text('ไม่สามารถโหลดข้อมูลผู้ใช้ได้',
                                style: GoogleFonts.kanit(
                                    color: Colors.white, fontSize: 16)),
                          )
                        : SingleChildScrollView(
                            child: Column(children: [
                              _profileCard(user!),
                              _userInfoSection(user!)
                            ]),
                          ),
              ),
            ],
          ),
          Positioned(
              bottom: 20, left: 24, right: 24, child: _buildLogoutButton()),
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: ClipOval(
              child: Image.asset('assets/images/logo.png',
                  width: 100, height: 100, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE6D2CD),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedFontSize: 17,
        unselectedFontSize: 17,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
              icon: Image.asset('assets/icons/add.png', width: 24, height: 24),
              label: 'Add'),
          BottomNavigationBarItem(
              icon: Image.asset('assets/icons/wishlist-heart.png',
                  width: 24, height: 24),
              label: 'Target'),
          BottomNavigationBarItem(
              icon:
                  Image.asset('assets/icons/stats.png', width: 24, height: 24),
              label: 'Graph'),
          BottomNavigationBarItem(
              icon:
                  Image.asset('assets/icons/accout.png', width: 24, height: 24),
              label: 'Account'),
        ],
      ),
    );
  }
}
