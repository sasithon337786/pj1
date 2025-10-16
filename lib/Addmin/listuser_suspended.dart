import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/models/userModel.dart';

class ListuserSuspended extends StatefulWidget {
  const ListuserSuspended({Key? key}) : super(key: key);

  @override
  State<ListuserSuspended> createState() => _ListuserSuspendedState();
}

class _ListuserSuspendedState extends State<ListuserSuspended> {
  final Color _bg = const Color(0xFFC98993);
  final Color _appBar = const Color(0xFF564843);
  final Color _card = const Color(0xFFEFEAE3);

  int _selectedIndex = 1; // หน้านี้คือแท็บ "บัญชีที่ระงับ"
  bool _loading = true;
  String? _error;

  List<UserModel> _allUsers = [];
  List<UserModel> _suspendedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      setState(() {
        _loading = false;
        _error = 'ยังไม่ล็อกอิน';
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final idToken = await current.getIdToken(true);

      // ถ้าแบ็กเอนด์รองรับ server-side filtering:
      // final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/auth/users?status=suspended');
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/auth/users');

      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode != 200) {
        throw Exception(
            'โหลดผู้ใช้ไม่สำเร็จ (${resp.statusCode}) ${resp.body}');
      }

      final data = jsonDecode(resp.body);
      final list = (data['users'] as List<dynamic>? ?? [])
          .map((j) => UserModel.fromJson(j))
          .toList();

      // กรองสถานะระงับ (ครอบคลุมกรณี ban/blocked ด้วย)
      final suspended = list.where((u) {
        final s = (u.status ?? '').toLowerCase().trim();
        return s == 'suspended' || s == 'ban' || s == 'blocked';
      }).toList();

      setState(() {
        _allUsers = list;
        _suspendedUsers = suspended;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ดึงข้อมูลไม่สำเร็จ: $e', style: GoogleFonts.kanit()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unsuspendUser(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFE6D2CD),
        title: Text('ยืนยันการยกเลิกการระงับ',
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _appBar,
            )),
        content: Text(
          'ต้องการยกเลิกการระงับบัญชีของ ${user.username.isNotEmpty ? user.username : user.email} ใช่หรือไม่?',
          style: GoogleFonts.kanit(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: GoogleFonts.kanit(color: _bg)),
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
      ),
    );

    if (ok != true) return;

    try {
      final idToken = await FirebaseAuth.instance.currentUser!.getIdToken(true);
      final payload = {
        'uid': user.uid,
        'status': 'active',
        'reason': 'unsuspend from suspended list',
      };

      final resp = await http.put(
        Uri.parse('${ApiEndpoints.baseUrl}/api/users/changeStatus'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
        final msg =
            body['message']?.toString() ?? '(${resp.statusCode}) ${resp.body}';
        throw Exception(msg);
      }

      // อัปเดตหน้าให้หายไปจากรายการทันที
      setState(() {
        _suspendedUsers.removeWhere((u) => u.uid == user.uid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ยกเลิกการระงับสำเร็จ', style: GoogleFonts.kanit()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ทำรายการไม่สำเร็จ: $e', style: GoogleFonts.kanit()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAdmin()),
        );
        break;
      case 1:
        // หน้าปัจจุบัน
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
      backgroundColor: _bg,
      body: Column(
        children: [
          // Header โลโก้สไตล์เดียวกับหน้าอื่น
          Stack(
            children: [
              Column(
                children: [
                  Container(
                    color: _appBar,
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

          // ป้าย "Admin"
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _appBar,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/icons/admin.png',
                          width: 20, height: 20),
                      const SizedBox(width: 8),
                      Text('Admin',
                          style: GoogleFonts.kanit(
                              fontSize: 18, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // เนื้อหา
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUsers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/icons/noaccount.png',
                                width: 35, height: 35),
                            const SizedBox(width: 8),
                            Text('บัญชีที่ระงับแล้ว',
                                style: GoogleFonts.kanit(
                                    fontSize: 22, color: _appBar)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(_error!,
                                  style: GoogleFonts.kanit(color: Colors.red)),
                            ),
                          )
                        else if (_suspendedUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('ไม่มีบัญชีที่ถูกระงับ',
                                  style: GoogleFonts.kanit(
                                      fontSize: 18, color: Colors.grey)),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _suspendedUsers.length,
                            itemBuilder: (context, index) {
                              final u = _suspendedUsers[index];
                              final name =
                                  (u.username.isNotEmpty ? u.username : u.email)
                                      .trim();
                              final role = (u.role ?? 'user').toLowerCase();

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _appBar,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.kanit(
                                                  fontSize: 20,
                                                  color: Colors.white)),
                                          const SizedBox(height: 2),
                                          Text('Role: $role',
                                              style: GoogleFonts.kanit(
                                                  fontSize: 14,
                                                  color: Colors.white70)),
                                          Text('Status: suspended',
                                              style: GoogleFonts.kanit(
                                                  fontSize: 14,
                                                  color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _unsuspendUser(u),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE6D2CD),
                                        foregroundColor: _appBar,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                      ),
                                      child: Text('ยกเลิกการระงับ',
                                          style: GoogleFonts.kanit(
                                              fontSize: 15,
                                              color: Colors.white)),
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
