import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_petition.dart';
import 'package:pj1/Addmin/main_Addmin.dart';

class ListuserSuspended extends StatefulWidget {
  const ListuserSuspended({Key? key}) : super(key: key);

  @override
  State<ListuserSuspended> createState() => _ListuserSuspendedState();
}

class _ListuserSuspendedState extends State<ListuserSuspended> {
  final List<String> users = ['Nutty', 'แฟรงค์', 'Mozel', 'คิวคิวคิว'];

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
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFC98993),
        body: Column(
          children: [
            // Header UI
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
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF564843),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset('assets/icons/admin.png',
                            width: 20, height: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Addmin',
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

            // Content User List
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
                              'assets/icons/noaccount.png',
                              width: 35,
                              height: 35,
                            ),
                            const SizedBox(
                                width: 8), // เพิ่มช่องว่างระหว่าง icon กับ text
                            Text(
                              'บัญชีที่ระงับแล้ว',
                              style: GoogleFonts.kanit(
                                fontSize: 22,
                                color: const Color(0xFF564843),
                              ),
                            ),
                          ],
                        ),
                        // รายการ Users
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
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
                                  Text(
                                    users[index],
                                    style: GoogleFonts.kanit(
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // *** เริ่มต้นส่วนของ AlertDialog ***
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          // ตัวแปรสำหรับเก็บค่าปุ่มที่ถูกเลือก: -1 = ยังไม่เลือก, 0 = 'ไม่', 1 = 'ใช่'
                                          int selectedIndex = -1;

                                          return StatefulBuilder(
                                            // ใช้ StatefulBuilder เพื่อให้ AlertDialog สามารถอัปเดต UI ภายในได้
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                backgroundColor:
                                                    const Color(0xFFE6D2CD),
                                                title: Text(
                                                  'ยืนยันการยกเลิกการระงับ',
                                                  style: GoogleFonts.kanit(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF564843),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                content: Text(
                                                  'ต้องการยกเลิกการระงับบัญชีผู้ใช้นี้ใช่หรือไม่?',
                                                  style: GoogleFonts.kanit(
                                                    fontSize: 18,
                                                    color:
                                                        const Color(0xFF3E3E3E),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                actionsAlignment:
                                                    MainAxisAlignment.center,
                                                actionsPadding:
                                                    const EdgeInsets.only(
                                                        bottom: 12),
                                                actions: [
                                                  // ปุ่ม "ไม่"
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      // กำหนดสีตาม selectedIndex: ถ้า selectedIndex เป็น 0 (ไม่) ให้เป็นสีเข้ม, ถ้าไม่ใช่ให้เป็นสีปกติ
                                                      backgroundColor: selectedIndex ==
                                                              0
                                                          ? const Color(
                                                              0xFF564843) // สีเมื่อถูกเลือก
                                                          : const Color(
                                                              0xFFC98993), // สีปกติ
                                                      foregroundColor: Colors
                                                          .white, // สีตัวอักษร
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 28,
                                                          vertical: 12),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        // อัปเดต UI ภายใน AlertDialog
                                                        selectedIndex =
                                                            0; // ตั้งค่าว่าเลือก 'ไม่'
                                                      });
                                                      // Navigator.of(context).pop(); // ยังไม่ปิด AlertDialog ทันที
                                                    },
                                                    child: Text(
                                                      'ไม่',
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          10), // เพิ่มระยะห่างระหว่างปุ่ม

                                                  // ปุ่ม "ใช่"
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      // กำหนดสีตาม selectedIndex: ถ้า selectedIndex เป็น 1 (ใช่) ให้เป็นสีเข้ม, ถ้าไม่ใช่ให้เป็นสีปกติ
                                                      backgroundColor: selectedIndex ==
                                                              1
                                                          ? const Color(
                                                              0xFF564843) // สีเมื่อถูกเลือก
                                                          : const Color(
                                                              0xFFC98993), // สีปกติ
                                                      foregroundColor: Colors
                                                          .white, // สีตัวอักษร
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 28,
                                                          vertical: 12),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        // อัปเดต UI ภายใน AlertDialog
                                                        selectedIndex =
                                                            1; // ตั้งค่าว่าเลือก 'ใช่'
                                                      });
                                                      // Navigator.of(context).pop(); // ยังไม่ปิด AlertDialog ทันที
                                                    },
                                                    child: Text(
                                                      'ใช่',
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      // *** สิ้นสุดส่วนของ AlertDialog ***
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE6D2CD),
                                      foregroundColor: const Color(0xFF564843),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'ยกเลิกการระงับ',
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

        // Bottom Navigation Bar
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
}
