import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/login.dart';
import 'package:pj1/models/userModel.dart';

// Import หน้าอื่นๆ ของแอดมินที่คุณมี
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/models/userModel.dart';

// ====== นำทางไปหน้าจาก navbar (ถ้ามีไฟล์เหล่านี้อยู่แล้ว) ======
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';

/// endpoints
class _Endpoints {
  static String get base => ApiEndpoints.baseUrl;
  static String editSelf() => '$base/api/users/edit';
  static String suspendUser(String uid) => '$base/api/admin/users/$uid/suspend';
  static String deleteUser(String uid) => '$base/api/admin/users/$uid';
}

/// ===== helper ปลอดภัยกับ null =====
bool _has(String? s) => s?.trim().isNotEmpty ?? false;
String _or(String? s, String fallback) => _has(s) ? s!.trim() : fallback;

class UserInfoScreen extends StatefulWidget {
  final UserModel user;
  const UserInfoScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  // โทนสี
  final Color _bg = const Color(0xFFC98993);
  final Color _appBar = const Color(0xFF564843);
  final Color _card = const Color(0xFFEFEAE3);
  final Color _pill = const Color(0xFFE6D2CD);
  final Color _accent = const Color(0xFFC98993);

  late UserModel _user;
  bool _busy = false;

  // สำหรับ navbar
  int _selectedIndex = 0; // 0 = User

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  // ============== HEADER (โลโก้ + back) ==============
  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Column(
          children: [
            Container(
              color: _appBar,
              height: topPad + 80,
              width: double.infinity,
            ),
            const SizedBox(height: 60),
          ],
        ),
        // โลโก้ตรงกลาง
        Positioned(
          top: topPad + 30,
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // ปุ่มย้อนกลับซ้ายบน
        Positioned(
          top: topPad + 16,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 6),
                Text('ย้อนกลับ',
                    style:
                        GoogleFonts.kanit(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _or(_user.username, _or(_user.email, ''));
    final role = _or(_user.role, 'user').toLowerCase();
    final status = _or(_user.status, 'active').toLowerCase();
    final birthdayStr = _formatBirthday(_user.birthday);
    final statusStyle = _statusStyle(status);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bg, _bg.withOpacity(0.88)],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // ==== Header แบบโลโก้ (แทน AppBar) ====
                _buildHeader(context),

                // ======= เนื้อหาการ์ด =======
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      // การ์ดโปรไฟล์
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFD7B1B1),
                                    _appBar.withOpacity(0.55)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 54,
                                backgroundColor: _card,
                                child: ClipOval(
                                    child: _buildAvatar(_user.photoUrl)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.kanit(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _appBar,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _chip(
                                  icon: Icons.verified_user_rounded,
                                  label: role == 'admin' ? 'Admin' : 'User',
                                  bg: role == 'admin'
                                      ? const Color(0xFF3B6C8A)
                                          .withOpacity(0.15)
                                      : Colors.green.withOpacity(0.12),
                                  fg: role == 'admin'
                                      ? const Color(0xFF3B6C8A)
                                      : Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                _chip(
                                  icon: statusStyle.icon,
                                  label: statusStyle.label,
                                  bg: statusStyle.bg,
                                  fg: statusStyle.fg,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // การ์ดข้อมูลบัญชี
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6F3),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _sectionTitle('ข้อมูลบัญชี'),
                            const SizedBox(height: 8),
                            _infoTile(
                                icon: Icons.email_rounded,
                                title: 'Email',
                                value: _or(_user.email, 'N/A')),
                            const SizedBox(height: 10),
                            _infoTile(
                                icon: Icons.fingerprint_rounded,
                                title: 'UID',
                                value: _or(_user.uid, 'N/A')),
                            const SizedBox(height: 10),
                            _infoTile(
                              icon: Icons.badge_rounded,
                              title: 'Username',
                              value: _or(_user.username, 'N/A'),
                            ),
                            const SizedBox(height: 10),
                            _infoTile(
                                icon: Icons.cake_rounded,
                                title: 'Birthday',
                                value: birthdayStr),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // การ์ดการจัดการบัญชี
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionTitle('การจัดการบัญชี'),
                            const SizedBox(height: 12),
                            _actionButton(
                              icon: Icons.edit_rounded,
                              label: 'แก้ไขข้อมูลผู้ใช้',
                              bg: _appBar,
                              onTap:
                                  _busy ? null : () => _openEditDialog(context),
                            ),
                            const SizedBox(height: 10),
                            _actionButton(
                              icon: Icons.pause_circle_filled_rounded,
                              label: 'ระงับบัญชีผู้ใช้',
                              bg: Colors.orange.shade600,
                              onTap: _busy
                                  ? null
                                  : () => _confirmAndSuspend(context),
                            ),
                            const SizedBox(height: 10),
                            _actionButton(
                              icon: Icons.delete_forever_rounded,
                              label: 'ลบบัญชีผู้ใช้',
                              bg: Colors.red.shade700,
                              onTap: _busy
                                  ? null
                                  : () => _confirmAndDelete(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // ================== Edit Dialog | ใช้เส้น /api/users/edit ==================
  void _openEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _or(_user.username, ''));
    final emailCtrl = TextEditingController(text: _or(_user.email, ''));
    final bdayCtrl = TextEditingController(
      text: _user.birthday != null
          ? DateFormat('dd/MM/yyyy').format(_user.birthday!)
          : '',
    );

    final formKey = GlobalKey<FormState>();

    String? _required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'กรุณากรอกข้อมูล' : null;

    String? _email(String? v) {
      if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
      return ok ? null : 'อีเมลไม่ถูกต้อง';
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
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffix,
      );
    }

    Future<void> _pickBirthday(StateSetter setDState) async {
      final now = DateTime.now();
      final initial =
          _user.birthday ?? DateTime(now.year - 18, now.month, now.day);
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
        bdayCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
        setDState(() {});
      }
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
                final idToken =
                    await FirebaseAuth.instance.currentUser!.getIdToken(true);

                final payload = {
                  'username': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'birthday': bdayCtrl.text.trim().isEmpty
                      ? null
                      : DateFormat('yyyy-MM-dd').format(
                          DateFormat('dd/MM/yyyy').parse(bdayCtrl.text.trim()),
                        ),
                };

                final resp = await http.put(
                  Uri.parse(_Endpoints.editSelf()),
                  headers: {
                    'Authorization': 'Bearer $idToken',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(payload),
                );

                if (resp.statusCode >= 200 && resp.statusCode < 300) {
                  if (!mounted) return;
                  setState(() {
                    _user = UserModel(
                      uid: _or(_user.uid, ''),
                      email: _or(emailCtrl.text, _or(_user.email, '')),
                      username: _or(nameCtrl.text, _or(_user.username, '')),
                      role: _or(_user.role, 'user'),
                      status: _or(_user.status, 'active'),
                      photoUrl: _or(_user.photoUrl, ''),
                      birthday: (() {
                        try {
                          return bdayCtrl.text.trim().isEmpty
                              ? null
                              : DateFormat('dd/MM/yyyy')
                                  .parse(bdayCtrl.text.trim());
                        } catch (_) {
                          return _user.birthday;
                        }
                      })(),
                    );
                  });

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('อัปเดตข้อมูลเรียบร้อย')),
                  );
                } else {
                  final Map<String, dynamic> body =
                      (resp.body.isNotEmpty) ? jsonDecode(resp.body) : {};
                  final msg = body['message']?.toString() ??
                      'อัปเดตไม่สำเร็จ (HTTP ${resp.statusCode})';
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                }
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
                  Text('แก้ไขข้อมูลผู้ใช้',
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
                        validator: (_) => null, // ไม่บังคับเลือกวันเกิด
                        style: GoogleFonts.kanit(),
                        decoration: _dec('วันเกิด (วัน/เดือน/ปี)',
                            suffix: const Icon(Icons.calendar_today)),
                      ),
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
                                strokeWidth: 2, color: Colors.white))
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

  // ================== Actions (Suspend/Delete) ==================
  Future<void> _confirmAndSuspend(BuildContext context) async {
    final ok = await _confirmDialog(
      context,
      title: 'ยืนยันการระงับบัญชี',
      content: 'ต้องการระงับบัญชีของผู้ใช้นี้หรือไม่?',
      confirmText: 'ระงับบัญชี',
      danger: true,
    );
    if (ok != true) return;

    await _callAction(
      request: () async {
        final idToken =
            await FirebaseAuth.instance.currentUser?.getIdToken(true);
        final url = Uri.parse(_Endpoints.suspendUser(_user.uid));
        final resp = await http.post(url, headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        });
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          if (!mounted) return;
          setState(() {
            _user = UserModel(
              uid: _user.uid,
              email: _user.email,
              username: _user.username,
              role: _user.role,
              status: 'suspended',
              photoUrl: _user.photoUrl,
              birthday: _user.birthday,
            );
          });
        } else {
          throw Exception('(${resp.statusCode}) ${resp.body}');
        }
      },
      success: 'ระงับบัญชีสำเร็จ',
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final ok = await _confirmDialog(
      context,
      title: 'ลบบัญชีผู้ใช้',
      content: 'การลบไม่สามารถย้อนกลับได้ ต้องการลบผู้ใช้นี้หรือไม่?',
      confirmText: 'ลบถาวร',
      danger: true,
    );
    if (ok != true) return;

    await _callAction(
      request: () async {
        final idToken =
            await FirebaseAuth.instance.currentUser?.getIdToken(true);
        final url = Uri.parse(_Endpoints.deleteUser(_user.uid));
        final resp = await http.delete(url, headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        });
        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          throw Exception('(${resp.statusCode}) ${resp.body}');
        }
      },
      success: 'ลบบัญชีสำเร็จ',
      afterSuccess: () {
        if (!mounted) return;
        Navigator.pop(context);
      },
    );
  }

  // ================== Small UI Parts ==================
  Widget _buildAvatar(String? url) {
    if (_has(url)) {
      return Image.network(
        url!,
        width: 108,
        height: 108,
        fit: BoxFit.cover,
        loadingBuilder: (c, w, p) => p == null
            ? w
            : const SizedBox(
                width: 108,
                height: 108,
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2))),
        errorBuilder: (_, __, ___) =>
            Icon(Icons.person, size: 68, color: _appBar.withOpacity(0.6)),
      );
    }
    return Icon(Icons.person, size: 68, color: _appBar.withOpacity(0.6));
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
            height: 18,
            width: 6,
            decoration: BoxDecoration(
                color: _accent, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.kanit(
                fontSize: 18, fontWeight: FontWeight.w700, color: _appBar)),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.brown.shade100.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          _iconBadge(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.kanit(
                        fontSize: 13, color: Colors.brown.shade700)),
                const SizedBox(height: 2),
                Text(_has(value) ? value : 'N/A',
                    style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _appBar)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A5A5), Color(0xFF8C6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.brown.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 6))
        ],
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color bg,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(label,
          style: GoogleFonts.kanit(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.kanit(
                  color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ================== Helpers ==================
  Future<void> _callAction({
    required Future<void> Function() request,
    String success = 'สำเร็จ',
    VoidCallback? afterSuccess,
  }) async {
    setState(() => _busy = true);
    try {
      await request();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(success, style: GoogleFonts.kanit()),
            backgroundColor: Colors.green),
      );
      afterSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('ทำรายการไม่สำเร็จ: $e', style: GoogleFonts.kanit()),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style:
                GoogleFonts.kanit(color: _appBar, fontWeight: FontWeight.w700)),
        content: Text(content, style: GoogleFonts.kanit(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: GoogleFonts.kanit(color: _accent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? Colors.red.shade700 : _appBar,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText,
                style: GoogleFonts.kanit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatBirthday(DateTime? d) {
    if (d == null) return 'N/A';
    final local = DateTime(d.year, d.month, d.day);
    return '${_pad2(local.day)}/${_pad2(local.month)}/${local.year}';
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'active':
        return _StatusStyle(
          icon: Icons.check_circle_rounded,
          label: 'Active',
          bg: Colors.green.withOpacity(0.12),
          fg: Colors.green.shade700,
        );
      case 'suspended':
      case 'ban':
      case 'blocked':
        return _StatusStyle(
          icon: Icons.pause_circle_filled_rounded,
          label: 'Suspended',
          bg: Colors.orange.withOpacity(0.14),
          fg: Colors.orange.shade800,
        );
      case 'deleted':
      case 'disabled':
        return _StatusStyle(
          icon: Icons.cancel_rounded,
          label: 'Deleted',
          bg: Colors.red.withOpacity(0.14),
          fg: Colors.red.shade700,
        );
      case 'pending':
      case 'petition':
        return _StatusStyle(
          icon: Icons.hourglass_bottom_rounded,
          label: 'Pending',
          bg: Colors.amber.withOpacity(0.14),
          fg: Colors.amber.shade900,
        );
      default:
        return _StatusStyle(
          icon: Icons.info_rounded,
          label: status.isEmpty ? 'Unknown' : status,
          bg: Colors.grey.withOpacity(0.14),
          fg: Colors.grey.shade800,
        );
    }
  }
}

class _StatusStyle {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  _StatusStyle(
      {required this.icon,
      required this.label,
      required this.bg,
      required this.fg});
}

class MainAdmin extends StatefulWidget {
  const MainAdmin({Key? key}) : super(key: key);

  @override
  State<MainAdmin> createState() => _MainAdminState();
}

class _MainAdminState extends State<MainAdmin> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _adminAccessToken; // **กลับมาแล้ว: ตัวแปรสำหรับเก็บ Access Token**

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAccessToken().then((_) {
      // **กลับมาแล้ว: โหลด token ก่อนแล้วค่อย fetch users**
      _fetchUsers();
    });
  }

  // **กลับมาแล้ว: ฟังก์ชันสำหรับโหลด Access Token จาก SharedPreferences**
  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminAccessToken = prefs.getString(
          'adminAccessToken'); // ต้องตรงกับ key ที่คุณใช้ตอนเก็บ token
    });
    if (_adminAccessToken == null) {
      print(
          'Error: Admin Access Token not found. Please ensure Admin is logged in.');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('กรุณาเข้าสู่ระบบในฐานะ Admin ก่อน'),
      //     backgroundColor: Colors.orange,
      //   ),
      // );
      // คุณอาจต้องการนำทางผู้ใช้กลับไปหน้า Login ที่นี่ด้วย
    }
  }

  Future<void> _fetchUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final idToken = await user.getIdToken(true);

      setState(() {
        _isLoading = true;
      });

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] != null) {
          final List<dynamic> userJsonList = data['users'];
          print('Fetched users count: ${userJsonList.length}');
          setState(() {
            _users =
                userJsonList.map((json) => UserModel.fromJson(json)).toList();
          });
        } else {
          print('No users key in response JSON');
        }
      } else {
        print(
            'Failed to fetch users. Status: ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch users: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error in _fetchUsers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('--- Loaded users ---');
      for (var u in _users) {
        print('${u.email} | ${u.username} | ${u.photoUrl}');
      }
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // _fetchUsers(); // อาจจะเรียก fetchUsers อีกครั้งเมื่อกด tab user
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListuserSuspended()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListuserDeleteAdmin()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListuserPetition()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Column(
        children: [
          Stack(
            children: [
              Column(
                children: [
                  Container(
                    color: const Color(0xFF564843),
                    height: MediaQuery.of(context).padding.top + 80,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 30,
                left: MediaQuery.of(context).size.width / 2 - 50,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          // ...
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    right: 16.0), // ✨ เพิ่ม padding ด้านขวาเฉพาะปุ่มนี้
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF564843),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    'ออกจากระบบ',
                    style: GoogleFonts.kanit(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/man.png',
                            width: 35,
                            height: 35,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'รายชื่อผู้ใช้ทั้งหมด',
                            style: GoogleFonts.kanit(
                              fontSize: 22,
                              color: const Color(0xFF564843),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _users.isEmpty
                              ? Center(
                                  child: Text(
                                    'ไม่พบข้อมูลผู้ใช้',
                                    style: GoogleFonts.kanit(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _users.length,
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF564843),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.username.isNotEmpty
                                                    ? user.username
                                                    : user.email,
                                                style: GoogleFonts.kanit(
                                                  fontSize: 22,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'Role: ${user.role}',
                                                style: GoogleFonts.kanit(
                                                  fontSize: 16,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              Text(
                                                'Status: ${user.status}',
                                                style: GoogleFonts.kanit(
                                                  fontSize: 16,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      UserInfoScreen(
                                                          user: user),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFE6D2CD),
                                              foregroundColor:
                                                  const Color(0xFF564843),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              textStyle:
                                                  const TextStyle(fontSize: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Text(
                                              'รายละเอียด',
                                              style: GoogleFonts.kanit(
                                                fontSize: 15,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ),
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
        selectedLabelStyle: GoogleFonts.kanit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        unselectedLabelStyle: GoogleFonts.kanit(
          fontSize: 17,
          fontWeight: FontWeight.normal,
          color: Colors.white60,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/accout.png', width: 24, height: 24),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/deactivate.png',
                width: 30, height: 30),
            label: 'บัญชีที่ระงับ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/social-media-management.png',
                width: 24, height: 24), // เปลี่ยนไอคอน
            label: 'Manage', // เปลี่ยนข้อความ
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/wishlist-heart.png',
                width: 24, height: 24),
            label: 'คำร้อง',
          ),
        ],
      ),
    );
  }
}
