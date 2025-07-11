import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/Addmin/list_admin.dart';
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';

class DeteiluserSuspended extends StatefulWidget {
  final String userName;

  const DeteiluserSuspended({Key? key, required this.userName})
      : super(key: key);

  @override
  State<DeteiluserSuspended> createState() => _DeteiluserSuspendedState();
}

class _DeteiluserSuspendedState extends State<DeteiluserSuspended> {
  final Color primaryColor = const Color(0xFFEFEAE3);
  final Color secondaryColor = const Color(0xFF564843);
  final Color backgroundColor = const Color(0xFFC98993);
  final Color accentColor = const Color(0xFFE6D2CD);
  final Color lightTextColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    Container(
                      color: secondaryColor,
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/petition.png',
                          width: 35,
                          height: 35,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'คำร้อง',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.userName,
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ฉันต้องการให้ระงับบัญชีนี้เพราะมีปัญหาบางอย่างที่ไม่สามารถแก้ไขได้ด้วยตนเองและต้องการให้ผู้ดูแลระบบตรวจสอบและดำเนินการระงับบัญชีนี้เป็นการชั่วคราวหรือถาวรตามความเหมาะสมเพื่อรักษาความปลอดภัยของข้อมูลและป้องกันปัญหาที่อาจเกิดขึ้นในอนาคต ขอบคุณค่ะ',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        color: const Color(0xFF3E3E3E),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          print('ดูข้อมูลผู้ใช้: ${widget.userName}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: lightTextColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: GoogleFonts.kanit(fontSize: 16),
                        ),
                        icon: Image.asset(
                          'assets/icons/account.png',
                          width: 24,
                          height: 24,
                        ),
                        label: const Text('ข้อมูลผู้ใช้'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              int selectedIndex = -1;

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    backgroundColor: primaryColor,
                                    title: Text(
                                      'ยืนยันการการระงับ',
                                      style: GoogleFonts.kanit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: secondaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: Text(
                                      'ต้องการระงับบัญชีผู้ใช้ ${widget.userName} นี้ใช่หรือไม่?',
                                      style: GoogleFonts.kanit(
                                        fontSize: 18,
                                        color: const Color(0xFF3E3E3E),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actionsPadding:
                                        const EdgeInsets.only(bottom: 12),
                                    actions: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selectedIndex == 0
                                              ? secondaryColor
                                              : backgroundColor,
                                          foregroundColor: lightTextColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 28, vertical: 12),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedIndex = 0;
                                          });
                                          Navigator.of(context).pop();
                                          print(
                                              'ระงับบัญชี ${widget.userName}: ไม่');
                                        },
                                        child: Text(
                                          'ไม่',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
                                            color: lightTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selectedIndex == 1
                                              ? secondaryColor
                                              : backgroundColor,
                                          foregroundColor: lightTextColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 28, vertical: 12),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedIndex = 1;
                                          });
                                          Navigator.of(context).pop();
                                          print(
                                              'ระงับบัญชี ${widget.userName}: ใช่');
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const MainAdmin()),
                                            (Route<dynamic> route) => false,
                                          );
                                        },
                                        child: Text(
                                          'ใช่',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
                                            color: lightTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: secondaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          textStyle: GoogleFonts.kanit(fontSize: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          // เปลี่ยน child ของปุ่ม
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/deactivate.png', // ใช้ icon ที่หนูให้มา
                              width: 35,
                              height: 35,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ระงับบัญชีผู้ใช้', // ข้อความใหม่
                              style: GoogleFonts.kanit(
                                fontSize: 17,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
