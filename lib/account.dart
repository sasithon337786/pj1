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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final fetchedUser = await fetchUserProfile();
    setState(() {
      user = fetchedUser;
      isLoading = false;
    });
  }

  Future<UserModel?> fetchUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      print(currentUser?.uid);
      if (currentUser == null) return null;

      final idToken = await currentUser.getIdToken();
      print(idToken);
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/getProfile'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print(json);
        return UserModel.fromJson(json);
      } else {
        print("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching profile: $e");
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainHomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Targetpage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Graphpage()),
        );
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: MediaQuery.of(context).padding.top + 70,
                color: const Color(0xFF564843),
              ),
              const SizedBox(height: 54),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : user == null
                        ? const Center(child: Text('ไม่สามารถโหลดข้อมูลผู้ใช้ได้'))
                        : SingleChildScrollView(
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 24),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F1ED),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 50,
                                          backgroundImage: user!.photoUrl != null
                                              ? NetworkImage(user!.photoUrl!)
                                              : const AssetImage('assets/images/boy.png')
                                                  as ImageProvider,
                                        ),
                                        const SizedBox(height: 20),
                                        buildUserRow("Name", user!.username),
                                        buildUserRow("Email", user!.email),
                                        buildUserRow("Role", user!.role),
                                        buildUserRow("Status", user!.status),
                                        if (user!.birthday != null)
                                          buildUserRow(
                                            "Birthday",
                                            DateFormat('dd MMM yyyy')
                                                .format(user!.birthday!),
                                          ),
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            // TODO: Add Edit Profile screen
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF564843),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                          icon: const Icon(Icons.edit,
                                              size: 18, color: Colors.white),
                                          label: Text(
                                            'แก้ไขข้อมูลส่วนตัว',
                                            style: GoogleFonts.kanit(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 8),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // TODO: Add petition function
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF564843),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      icon: const Icon(Icons.person, color: Colors.white),
                                      label: Text(
                                        'ส่งคำร้อง',
                                        style: GoogleFonts.kanit(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
          // ปุ่ม logout แยกออกมาอยู่นอกเงื่อนไข
          Positioned(
            bottom: 20,
            left: 32,
            right: 32,
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/wishlist-heart.png',
                width: 24, height: 24),
            label: 'Target',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/stats.png', width: 24, height: 24),
            label: 'Graph',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/accout.png', width: 24, height: 24),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget buildUserRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
