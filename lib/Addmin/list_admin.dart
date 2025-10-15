import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/Addmin/userinfo.dart'; // ✅ หน้าปลายทาง
import 'package:pj1/models/userModel.dart';

class ListUserInfoScreen extends StatefulWidget {
  final String uid; // ✅ รับ uid
  const ListUserInfoScreen({super.key, required this.uid});

  @override
  State<ListUserInfoScreen> createState() => _ListUserInfoScreenState();
}

class _ListUserInfoScreenState extends State<ListUserInfoScreen> {
  int _selectedIndex = 0;
  UserModel? _detailUser;
  bool isLoading = true;
  String? errorText;

  int totalActivities = 0;
  int successActivities = 0;
  int failedActivities = 0;

  String displayName = '—';
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      final idToken = await fbUser?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      // 1) total_activities
      final countUri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activity/count',
      ).replace(queryParameters: {'uid': widget.uid});

      final countRes = await http.get(
        countUri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      if (countRes.statusCode != 200) {
        throw Exception('HTTP ${countRes.statusCode}: ${countRes.body}');
      }
      final cBody = json.decode(countRes.body) as Map<String, dynamic>;
      final int newTotal = (cBody['total_activities'] is int)
          ? cBody['total_activities'] as int
          : int.tryParse('${cBody['total_activities']}') ?? 0;

      // 2) success จาก summary
      final summaryUri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activity/summary',
      ).replace(queryParameters: {'uid': widget.uid});

      final summaryRes = await http.get(
        summaryUri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      if (summaryRes.statusCode != 200) {
        throw Exception('HTTP ${summaryRes.statusCode}: ${summaryRes.body}');
      }
      final sBody = json.decode(summaryRes.body) as Map<String, dynamic>;
      final sData = (sBody['data'] ?? sBody) as Map<String, dynamic>;

      int toInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v) ?? 0;
        return 0;
      }

      final int newSuccess = toInt(sData['success_activities']);
      final int newFailed =
          (newTotal - newSuccess) < 0 ? 0 : (newTotal - newSuccess);

      // 3) Profile -> ต้องสร้าง UserModel เพื่อเปิดปุ่ม
      String newDisplayName = '—';
      String? newPhotoUrl;
      UserModel? newDetailUser; // <<<<<<<<<<<<<< เพิ่มตัวแปรชั่วคราว

      try {
        final profileUri =
            Uri.parse('${ApiEndpoints.baseUrl}/api/users/${widget.uid}');
        final profileRes = await http.get(
          profileUri,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        );
        if (profileRes.statusCode == 200) {
          final pBody = json.decode(profileRes.body) as Map<String, dynamic>;
          final pData = pBody['data'] as Map<String, dynamic>?;
          if (pData != null) {
            final username = (pData['username'] ?? '').toString().trim();
            final email = (pData['email'] ?? '').toString().trim();
            newDisplayName = username.isNotEmpty
                ? username
                : (email.isNotEmpty ? email : '—');
            final rawPhoto = pData['photo_url']?.toString();
            newPhotoUrl =
                (rawPhoto != null && rawPhoto.isNotEmpty) ? rawPhoto : null;

            // ✅ สร้างโมเดลสำหรับส่งไป UserInfoScreen
            DateTime? parsedBirthday;
            final b = (pData['birthday'] ?? '').toString();
            if (b.isNotEmpty) parsedBirthday = DateTime.tryParse(b);

            newDetailUser = UserModel(
              uid: widget.uid,
              email: email,
              username: username,
              role: (pData['role'] ?? 'user').toString(),
              status: (pData['status'] ?? 'active').toString(),
              photoUrl: newPhotoUrl ?? '',
              birthday: parsedBirthday,
            );
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        totalActivities = newTotal;
        successActivities = newSuccess;
        failedActivities = newFailed;
        displayName = newDisplayName;
        photoUrl = newPhotoUrl;
        _detailUser = newDetailUser; // <<<<<<<<<<<<<< เซ็ตค่านี้เพื่อเปิดปุ่ม
        isLoading = false;
        errorText = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = e.toString();
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MainAdmin()));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ListuserSuspended()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ListuserDeleteAdmin()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ListuserPetition()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const appBarColor = Color(0xFF564843);
    const bgColor = Color(0xFFC98993);
    const cardColor = Color(0xFFEFEAE3);
    const infoBoxColor = Color(0xFFECD8D3);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header
          Stack(
            children: [
              Column(
                children: [
                  Container(
                    color: appBarColor,
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
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'ย้อนกลับ',
                        style: GoogleFonts.kanit(
                            color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // กล่องข้อมูลผู้ใช้ (ตัวเดียวพอ)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl!)
                      : const AssetImage('assets/icons/cat.jpg')
                          as ImageProvider,
                ),
                const SizedBox(height: 16),

                Text(
                  displayName,
                  style: GoogleFonts.kanit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: appBarColor,
                  ),
                ),

                const SizedBox(height: 15),

                // กล่องสรุปกิจกรรม
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: infoBoxColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child:
                                CircularProgressIndicator(color: appBarColor),
                          ),
                        )
                      : (errorText != null)
                          ? Column(
                              children: [
                                Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                                    style: GoogleFonts.kanit(
                                        fontSize: 18, color: appBarColor)),
                                const SizedBox(height: 6),
                                Text(errorText!,
                                    style: GoogleFonts.kanit(
                                        fontSize: 14, color: Colors.red),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadLatest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appBarColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('ลองใหม่',
                                      style: GoogleFonts.kanit()),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'กิจกรรมที่ผู้ใช้ทำทั้งหมด :  $totalActivities',
                                  style: GoogleFonts.kanit(
                                      fontSize: 18, color: appBarColor),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'กิจกรรมที่ผู้ใช้ทำสำเร็จ :  $successActivities',
                                  style: GoogleFonts.kanit(
                                      fontSize: 18, color: appBarColor),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'กิจกรรมที่ผู้ใช้ทำไม่สำเร็จ :  $failedActivities',
                                  style: GoogleFonts.kanit(
                                      fontSize: 18, color: appBarColor),
                                ),
                              ],
                            ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: (_detailUser == null)
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserInfoScreen(
                                user: _detailUser!, // ✅ ส่งโมเดลทั้งก้อน
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.account_circle),
                  label: Text('ข้อมูลผู้ใช้',
                      style: GoogleFonts.kanit(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF564843),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation
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
            fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
        unselectedLabelStyle: GoogleFonts.kanit(
            fontSize: 17, fontWeight: FontWeight.normal, color: Colors.white60),
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
                width: 24, height: 24),
            label: 'Manage',
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
