import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pj1/Addmin/main_Addmin.dart';

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
  static String changeStatus() => '$base/api/users/changeStatus';
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
            onTap: () => Navigator.pop(context, true),
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

    // ================== Change Status Dialog ==================
    void _openChangeStatusDialog(BuildContext context) {
      String selectedStatus = status; // ใช้ค่าปัจจุบันตรง ๆ

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool saving = false;

          return StatefulBuilder(
            builder: (ctx, setDState) {
              Future<void> _submitStatusChange() async {
                // ไม่อนุญาตให้เปลี่ยนเป็นสถานะเดิม
                if (selectedStatus == _user.status?.toLowerCase()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('สถานะเดิมอยู่แล้ว',
                            style: GoogleFonts.kanit())),
                  );
                  return;
                }

                setDState(() => saving = true);

                try {
                  final idToken =
                      await FirebaseAuth.instance.currentUser!.getIdToken(true);
                  final resp = await http.put(
                    Uri.parse(_Endpoints.changeStatus()),
                    headers: {
                      'Authorization': 'Bearer $idToken',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'uid': _user.uid,
                      'status':
                          selectedStatus, // 'active' | 'suspended' | 'deleted'
                    }),
                  );

                  if (resp.statusCode >= 200 && resp.statusCode < 300) {
                    if (!mounted) return;

                    // อัปเดตสถานะใน UI ปัจจุบัน
                    setState(() {
                      _user = UserModel(
                        uid: _user.uid,
                        email: _user.email,
                        username: _user.username,
                        role: _user.role,
                        status: selectedStatus,
                        photoUrl: _user.photoUrl,
                        birthday: _user.birthday,
                      );
                    });

                    // ปิด dialog ก่อน
                    Navigator.pop(ctx);

                    // ✅ รอจนทำงานเสร็จจาก backend แล้วค่อย navigate
                    if (selectedStatus == 'deleted') {
                      // แสดงแจ้งเตือนเล็กน้อยก่อนย้ายหน้า
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('ผู้ใช้ถูกลบเรียบร้อยแล้ว',
                                style: GoogleFonts.kanit()),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      // หน่วงเวลาเล็กน้อยให้ snackbar แสดงทัน
                      await Future.delayed(const Duration(milliseconds: 800));

                      // ✅ หลังจากแสดงข้อความแล้วค่อยเปลี่ยนหน้า
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainAdmin()),
                          (route) => false,
                        );
                      }

                      return; // ออกจากฟังก์ชัน
                    }

                    // ถ้าไม่ใช่ deleted แสดงข้อความปกติ
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('เปลี่ยนสถานะเรียบร้อยแล้ว',
                              style: GoogleFonts.kanit()),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    final Map<String, dynamic> body =
                        (resp.body.isNotEmpty) ? jsonDecode(resp.body) : {};
                    final msg = body['message']?.toString() ??
                        'เปลี่ยนสถานะไม่สำเร็จ (HTTP ${resp.statusCode})';

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg, style: GoogleFonts.kanit()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('เกิดข้อผิดพลาด: $e',
                            style: GoogleFonts.kanit()),
                        backgroundColor: Colors.red,
                      ),
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
                    Text('เปลี่ยนสถานะผู้ใช้',
                        style: GoogleFonts.kanit(
                            color: _appBar,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                    const SizedBox(height: 6),
                    Container(height: 2, color: _appBar.withOpacity(0.5)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สถานะปัจจุบัน: ${_statusStyle(selectedStatus).label}',
                        style: GoogleFonts.kanit(
                            fontSize: 14, color: Colors.grey.shade700)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'เลือกสถานะใหม่',
                        labelStyle: GoogleFonts.kanit(),
                        filled: true,
                        fillColor: _pill.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.kanit(color: Colors.black87),
                      dropdownColor: _card,
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Active'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'suspended',
                          child: Row(
                            children: [
                              Icon(Icons.pause_circle_filled,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text('Suspended'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'deleted',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Deleted'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    child: Text('ยกเลิก',
                        style: GoogleFonts.kanit(color: _accent)),
                  ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appBar,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : _submitStatusChange,
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
                              offset: Offset(0, 6),
                            ),
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
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionTitle('การจัดการบัญชี'),
                            const SizedBox(height: 12),

                            // เปลี่ยนสถานะผู้ใช้
                            _actionButton(
                              icon: Icons.swap_horiz_rounded,
                              label: 'เปลี่ยนสถานะผู้ใช้',
                              bg: const Color(0xFF6A4C93),
                              onTap: _busy
                                  ? null
                                  : () => _openChangeStatusDialog(context),
                            ),
                            const SizedBox(height: 10),

                            // แก้ไขข้อมูลผู้ใช้
                            _actionButton(
                              icon: Icons.edit_rounded,
                              label: 'แก้ไขข้อมูลผู้ใช้',
                              bg: _appBar,
                              onTap:
                                  _busy ? null : () => _openEditDialog(context),
                            ),
                            const SizedBox(height: 10),
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
    final emailCtrl =
        TextEditingController(text: _or(_user.email, '')); // ✅ แสดงอย่างเดียว
    final bdayCtrl = TextEditingController(
      text: _user.birthday != null
          ? DateFormat('dd/MM/yyyy').format(_user.birthday!)
          : '',
    );

    final formKey = GlobalKey<FormState>();

    String? _required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'กรุณากรอกข้อมูล' : null;

    InputDecoration _dec(String hint, {Widget? suffix, bool disabled = false}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.kanit(
          color: disabled ? Colors.black26 : Colors.black38,
        ),
        filled: true,
        fillColor: disabled ? Colors.grey.shade300 : _pill.withOpacity(0.6),
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

                // payload ไม่ส่ง email
                final payload = {
                  'username': nameCtrl.text.trim(),
                  'birthday': bdayCtrl.text.trim().isEmpty
                      ? null
                      : DateFormat('yyyy-MM-dd').format(
                          DateFormat('dd/MM/yyyy').parse(bdayCtrl.text.trim()),
                        ),
                };

                // เปลี่ยน URL เป็น route ของ admin และส่ง uid ของผู้ใช้ที่จะแก้ไข
                final uri = Uri.parse(
                  '${ApiEndpoints.baseUrl}/api/users/admineditusers/${_user.uid}',
                );

                final resp = await http.put(
                  uri,
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
                      email: _or(_user.email, ''),
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
                      // ✅ ฟิลด์ username (แก้ไขได้)
                      TextFormField(
                        controller: nameCtrl,
                        validator: _required,
                        style: GoogleFonts.kanit(),
                        decoration: _dec('ชื่อ'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),

                      // ✅ ฟิลด์ email (แสดงแต่แก้ไขไม่ได้)
                      TextFormField(
                        controller: emailCtrl,
                        enabled: false,
                        style: GoogleFonts.kanit(
                          color: Colors.black45,
                        ),
                        decoration:
                            _dec('อีเมล (ไม่สามารถแก้ไขได้)', disabled: true)
                                .copyWith(
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ✅ ฟิลด์ birthday (แก้ไขได้)
                      TextFormField(
                        controller: bdayCtrl,
                        readOnly: true,
                        onTap: () => _pickBirthday(setDState),
                        validator: (_) => null,
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
            await FirebaseAuth.instance.currentUser!.getIdToken(true);
        final resp = await http.put(
          Uri.parse(_Endpoints.changeStatus()),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'uid': _user.uid,
            'status': 'suspended', // ✅ ตรงกับ DB/Backend
          }),
        );

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
          final msg = body['message']?.toString() ??
              '(${resp.statusCode}) ${resp.body}';
          throw Exception(msg);
        }

        if (!mounted) return;
        setState(() {
          _user = UserModel(
            uid: _user.uid,
            email: _user.email,
            username: _user.username,
            role: _user.role,
            status: 'suspended', // ✅ อัปเดตใน local
            photoUrl: _user.photoUrl,
            birthday: _user.birthday,
          );
        });
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
            await FirebaseAuth.instance.currentUser!.getIdToken(true);
        final resp = await http.put(
          Uri.parse(_Endpoints.changeStatus()),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'uid': _user.uid,
            'status': 'deleted',
          }),
        );

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
          final msg = body['message']?.toString() ??
              '(${resp.statusCode}) ${resp.body}';
          throw Exception(msg);
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
      child: const Icon(Icons.person, color: Colors.white),
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
