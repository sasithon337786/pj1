import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';

class UserProfileEditPage extends StatefulWidget {
  const UserProfileEditPage({super.key});

  @override
  _UserProfileEditPageState createState() => _UserProfileEditPageState();
}

class _UserProfileEditPageState extends State<UserProfileEditPage> {
  final TextEditingController _nameController =
      TextEditingController(text: 'ไอ้อ้วน');
  final TextEditingController _emailController =
      TextEditingController(text: 'Nutty@example.com');
  final TextEditingController _birthdayController =
      TextEditingController(text: '22');
  final TextEditingController _passwordController =
      TextEditingController(text: 'nutty12345');
  final TextEditingController _confirmPasswordController =
      TextEditingController(text: 'nutty12345');

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainAdmin()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListuserSuspended()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListuserDeleteAdmin()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ListuserPetition()),
        );
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ย้อนกลับ',
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE3),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/icons/cat.jpg'),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileInputField('Username :', _nameController),
                      _buildProfileInputField('Email :', _emailController),
                      _buildProfileInputField(
                          'Birthday :', _birthdayController),
                      _buildProfileInputField('Password :', _passwordController,
                          obscureText: true),
                      _buildProfileInputField(
                          'Confirm Password :', _confirmPasswordController,
                          obscureText: true),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          print('Name: ${_nameController.text}');
                          print('Email: ${_emailController.text}');
                          print('Birthday: ${_birthdayController.text}');
                          print('Password: ${_passwordController.text}');
                          print(
                              'Confirm Password: ${_confirmPasswordController.text}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF564843),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/healthy.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ยืนยัน',
                              style: GoogleFonts.kanit(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
            icon: Image.asset('assets/icons/deactivate.png', width: 30, height: 30),
            label: 'บัญชีที่ระงับ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/social-media-management.png', width: 24, height: 24), // เปลี่ยนไอคอน
            label: 'Manage', // เปลี่ยนข้อความ
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/wishlist-heart.png', width: 24, height: 24),
            label: 'คำร้อง',
          ),
        ],
        ));
  }

  Widget _buildProfileInputField(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8), // ลด vertical padding ตรงนี้
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                  fontSize: 18, color: const Color(0xFF564843)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECD8D3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                style: GoogleFonts.kanit(
                    fontSize: 16, color: const Color(0xFF564843)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
