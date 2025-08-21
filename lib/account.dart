import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pj1/add.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/login.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/models/userModel.dart';
import 'package:pj1/target.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 3;
  UserModel? user;
  bool isLoading = true;

  // === สีตามสไตล์แอปของหนู ===
  final Color _bg = const Color(0xFFC98993); // พื้นหลังเพจ
  final Color _appBar = const Color(0xFF564843); // ส่วนหัวเข้ม
  final Color _card = const Color(0xFFEFEAE3); // สีการ์ด
  final Color _pill = const Color(0xFFE6D2CD); // แคปซูล/ปุ่มอ่อน
  final Color _accent = const Color(0xFFC98993); // ไฮไลต์หลัก

  // สถานะปุ่มออกจากระบบ
  bool _isLoggingOut = false;

  // -------------------- LOGOUT --------------------
  Future<void> _confirmAndLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _card,
          title: Text(
            'ยืนยันการออกจากระบบ',
            style:
                GoogleFonts.kanit(color: _appBar, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'แน่ใจหรือไม่ว่าจะออกจากระบบตอนนี้?',
            style: GoogleFonts.kanit(color: Colors.black87),
          ),
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
      await FirebaseAuth.instance.signOut();
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
  // ------------------------------------------------

  // =============== 👇 เพิ่มสำหรับ "ส่งคำร้อง" เป็น Dialog ===============
  InputDecoration _dialogFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.kanit(color: Colors.black38),
      filled: true,
      fillColor: _pill.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _openPetitionDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _textCtrl = TextEditingController();
    String? _type;
    bool _sending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDState) {
            Future<void> _submit() async {
              if (!_formKey.currentState!.validate()) return;
              setDState(() => _sending = true);

              try {
                // TODO: call API ส่งคำร้องจริงที่นี่
                // final uid = FirebaseAuth.instance.currentUser?.uid;
                // await http.post(... body: {'uid': uid, 'type': _type, 'message': _textCtrl.text})

                if (mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ส่งคำร้องเรียบร้อย')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ส่งคำร้องไม่สำเร็จ: $e')),
                  );
                }
              } finally {
                setDState(() => _sending = false);
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
                  Text(
                    'คำร้องระงับบัญชี',
                    style: GoogleFonts.kanit(
                        fontSize: 20,
                        color: _appBar,
                        fontWeight: FontWeight.w700),
                  ),
                  Container(
                      height: 2,
                      margin: const EdgeInsets.only(top: 6),
                      color: _appBar.withOpacity(0.5)),
                ],
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
<<<<<<< HEAD
                    TextFormField(
                      controller: _textCtrl,
                      maxLines: 3,
                      decoration:
                          _dialogFieldDecoration('Input your expectations....'),
                      style: GoogleFonts.kanit(),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณากรอกข้อความคำร้อง'
                          : null,
                    ),
                    const SizedBox(height: 12),
=======
                    // TextFormField(
                    //   controller: _textCtrl,
                    //   maxLines: 3,
                    //   decoration:
                    //       _dialogFieldDecoration('Input your expectations....'),
                    //   style: GoogleFonts.kanit(),
                    //   validator: (v) => (v == null || v.trim().isEmpty)
                    //       ? 'กรุณากรอกข้อความคำร้อง'
                    //       : null,
                    // ),
                    // const SizedBox(height: 12),
>>>>>>> 112abfcaf875c0a5f41170babd93e72e081d03e0
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: _dialogFieldDecoration('เลือกคำร้อง......'),
                      icon: Icon(Icons.arrow_drop_down, color: _appBar),
                      style: GoogleFonts.kanit(color: Colors.black87),
                      items: const [
                        DropdownMenuItem(
<<<<<<< HEAD
                            value: 'ลบบัญชี', child: Text('ลบบัญชี')),
                        DropdownMenuItem(
                            value: 'ระงับบัญชี', child: Text('ระงับบัญชี')),
                        DropdownMenuItem(
                            value: 'ยกเลิกระงับบัญชี',
=======
                            value: 'delete', child: Text('ลบบัญชี')),
                        DropdownMenuItem(
                            value: 'suspend', child: Text('ระงับบัญชี')),
                        DropdownMenuItem(
                            value: 'unsuspend',
>>>>>>> 112abfcaf875c0a5f41170babd93e72e081d03e0
                            child: Text('ยกเลิกระงับบัญชี')),
                      ],
                      onChanged: (v) => setDState(() => _type = v),
                      validator: (v) =>
                            v == null ? 'กรุณาเลือกประเภทคำร้อง' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
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
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Confirm',
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
  // =================================================

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
        final json = jsonDecode(response.body);
        return UserModel.fromJson(json);
      } else {
        debugPrint("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
    return null;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const MainHomeScreen()));
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

  // ---------- UI Helpers ----------
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
        ? DateFormat('dd MMM yyyy').format(u.birthday!)
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
                        style: GoogleFonts.kanit(
                            fontSize: 20,
                            color: _accent,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(mail,
                        style: GoogleFonts.kanit(
                            fontSize: 14, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
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
          // ปุ่มคู่: แก้ไข / ส่งคำร้อง
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add Edit Profile screen
                  },
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
                  onPressed: _openPetitionDialog, // <<< เปิดไดอาล็อกที่เพิ่มไว้
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
                value: DateFormat('dd MMM yyyy').format(u.birthday!)),
        ],
      ),
    );
  }

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
                  width: double.infinity),
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

          // ปุ่ม Logout (ลอยล่าง)
          Positioned(
              bottom: 20, left: 24, right: 24, child: _buildLogoutButton()),

          // โลโก้บน
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: ClipOval(
              child: Image.asset('assets/images/logo.png',
                  width: 100, height: 100, fit: BoxFit.cover),
            ),
          ),

          // ปุ่มย้อนกลับ
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const HomePage()));
              },
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE6D2CD),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedFontSize: 17,
        unselectedFontSize: 17,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        //if status = suspend => not show navigation bar
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
