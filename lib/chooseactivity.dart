import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

// *** เพิ่มการ import ไฟล์ ApiEndpoints ที่นี่ ***
import 'package:pj1/constant/api_endpoint.dart'; // ตรวจสอบพาธให้ถูกต้องตามที่คุณจัดเก็บไฟล์

class ChooseactivityPage extends StatefulWidget {
  final int? actId;
  final String? activityName;
  final String? activityIconPath;
  final bool isNetworkImage;

  const ChooseactivityPage({
    super.key,
    this.actId,
    this.activityName,
    this.activityIconPath,
    this.isNetworkImage = false,
  });

  @override
  State<ChooseactivityPage> createState() => _ChooseactivityPageState();
}

class _ChooseactivityPageState extends State<ChooseactivityPage> {
  // *** แก้ไขตรงนี้: ทำให้ selectedTimes เป็น List เปล่าในตอนแรก ***
  List<TimeOfDay> selectedTimes = [];

  TextEditingController goalController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  bool isWeekSelected = true; // false = Day, true = Week
  int _selectedIndex = 0;
  String selectedUnit = 'Type';

  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      print('Current User UID: $currentUserId');
    } else {
      print('No user is currently logged in.');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Targetpage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Graphpage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountPage()),
        );
        break;
    }
  }

  Future<void> _addTimeReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        // ตรวจสอบว่าเวลานี้ถูกเลือกไปแล้วหรือไม่ เพื่อป้องกันการเพิ่มซ้ำ
        if (!selectedTimes.contains(picked)) {
          selectedTimes.add(picked);
          selectedTimes.sort((a, b) =>
              (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        }
      });
    }
  }

  // เพิ่มฟังก์ชันสำหรับลบเวลาที่เลือกออก (Optional แต่มีประโยชน์)
  void _removeTimeReminder(TimeOfDay timeToRemove) {
    setState(() {
      selectedTimes.remove(timeToRemove);
    });
  }

  void _showUnitPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController newUnitController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFE6D2CD),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'เลือกประเภทหน่วย',
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      color: const Color(0xFF5A4330),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      'ml',
                      'm',
                      'km',
                      'hr',
                      'min',
                      'cal',
                      'ครั้ง',
                      'เซต'
                    ].map((unit) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedUnit = unit;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedUnit == unit
                                ? const Color(0xFF564843)
                                : const Color(0xFFC98993),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            unit,
                            style: GoogleFonts.kanit(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: const Color(0xFFE6D2CD),
                            title: Text(
                              'เพิ่มหน่วยใหม่',
                              style: GoogleFonts.kanit(
                                fontSize: 20,
                                color: const Color(0xFF5A4330),
                              ),
                            ),
                            content: TextField(
                              controller: newUnitController,
                              style: GoogleFonts.kanit(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: 'เช่น แก้ว, ถ้วย, เซต',
                                hintStyle:
                                    GoogleFonts.kanit(color: Colors.grey),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'ยกเลิก',
                                  style: GoogleFonts.kanit(color: Colors.red),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (newUnitController.text.isNotEmpty) {
                                    setState(() {
                                      selectedUnit = newUnitController.text;
                                    });
                                    Navigator.pop(
                                        context); // ปิด Dialog เพิ่มหน่วย
                                    Navigator.pop(
                                        context); // ปิด Dialog เลือกหน่วย
                                  }
                                },
                                child: Text(
                                  'เพิ่ม',
                                  style: GoogleFonts.kanit(
                                      color: const Color(0xFF5A4330)),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF564843),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'เพิ่มหน่วยเอง',
                      style: GoogleFonts.kanit(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _saveActivityDetail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAlertDialog('Error', 'กรุณาเข้าสู่ระบบก่อนบันทึกข้อมูล');
      return;
    }
    final idToken = await user.getIdToken(true);

    if (widget.actId == null) {
      _showAlertDialog('Error', 'ไม่พบ ID กิจกรรม กรุณาลองใหม่');
      return;
    }

    // ✅ validate
    final parsedGoal = double.tryParse(goalController.text.trim());
    if (parsedGoal == null || parsedGoal <= 0) {
      _showAlertDialog('ข้อมูลไม่ครบถ้วน', 'กรุณากรอก Goal ให้ถูกต้อง (> 0)');
      return;
    }
    if (selectedUnit == 'Type') {
      _showAlertDialog('ข้อมูลไม่ครบถ้วน', 'กรุณาเลือกหน่วย (Unit)');
      return;
    }
    if (messageController.text.trim().isEmpty) {
      _showAlertDialog(
          'ข้อมูลไม่ครบถ้วน', 'กรุณากรอกข้อความเตือน (Reminder message)');
      return;
    }
    if (selectedTimes.isEmpty) {
      _showAlertDialog(
          'ข้อมูลไม่ครบถ้วน', 'กรุณาเพิ่มเวลาเตือนอย่างน้อย 1 เวลา');
      return;
    }

    // ✅ format เวลาเป็น ["HH:mm", ...]
    final List<String> timeRemindStrings = selectedTimes.map((t) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }).toList();

    // ✅ Day / Week
    final String roundValueForDB = isWeekSelected ? 'Week' : 'Day';

    final String apiUrl =
        '${ApiEndpoints.baseUrl}/api/activityDetail/addActivityDetail';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $idToken', // ✅ ใช้ token
        },
        body: jsonEncode({
          'act_id': widget.actId,
          'goal': parsedGoal,
          'unit': selectedUnit,
          'round': roundValueForDB,
          'message': messageController.text.trim(),
          'time_remind': timeRemindStrings,
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        _showAlertDialog('สำเร็จ', 'บันทึกข้อมูลกิจกรรมเรียบร้อยแล้ว!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        String? msg;
        try {
          final body = jsonDecode(response.body);
          msg = body['message']?.toString();
        } catch (_) {
          msg = null;
        }
        _showAlertDialog('เกิดข้อผิดพลาด',
            msg ?? 'ไม่สามารถบันทึกข้อมูลได้ (code: ${response.statusCode})');
        debugPrint(
            'save detail failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _showAlertDialog('เกิดข้อผิดพลาดในการเชื่อมต่อ',
          'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e');
      debugPrint('save detail error: $e');
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.kanit()),
          content: Text(message, style: GoogleFonts.kanit()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: GoogleFonts.kanit()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF564843),
              height: MediaQuery.of(context).padding.top + 80,
              width: double.infinity,
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white),
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
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 80,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6D2CD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (widget.activityIconPath != null &&
                                widget.activityIconPath!.isNotEmpty)
                              widget.isNetworkImage
                                  ? Image.network(
                                      widget.activityIconPath!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.grey,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      widget.activityIconPath!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                            if (widget.activityIconPath != null &&
                                widget.activityIconPath!.isNotEmpty)
                              const SizedBox(width: 10),
                            Text(
                              widget.activityName ?? 'ไม่พบชื่อกิจกรรม',
                              style: GoogleFonts.kanit(
                                fontSize: 22,
                                color: const Color(0xFF564843),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Goal & Goal Period',
                          style: GoogleFonts.kanit(
                              fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF564843),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextField(
                                  controller: goalController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.kanit(color: Colors.white),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Goal (เช่น 10)',
                                    hintStyle: GoogleFonts.kanit(
                                        color: Colors.white54),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showUnitPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEAE3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  selectedUnit,
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: const Color(0xFFC98993),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // ส่วนที่เลือก Day/Week
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isWeekSelected = false; // เลือก Day
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isWeekSelected
                                          ? const Color(0xFFF5E6E6)
                                          : const Color(0xFFC98993),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Day',
                                      style: GoogleFonts.kanit(
                                        color: isWeekSelected
                                            ? const Color(0xFF5A4330)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isWeekSelected = true; // เลือก Week
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isWeekSelected
                                          ? const Color(0xFFC98993)
                                          : const Color(0xFFF5E6E6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Week',
                                      style: GoogleFonts.kanit(
                                        color: isWeekSelected
                                            ? Colors.white
                                            : const Color(0xFF5A4330),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            //edit value
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Reminders',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC98993),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isWeekSelected ? 'Week' : 'Day', // แสดงผลการเลือก
                            style: GoogleFonts.kanit(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Time reminders',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // *** ปรับปรุง Logic การแสดงผลตรงนี้ ***
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            // แสดงเวลาที่เลือกเท่านั้น ถ้ามี
                            ...selectedTimes.map((time) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF564843),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    // ใช้ Row เพื่อรวมเวลาและปุ่มลบ
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        time.format(context),
                                        style: GoogleFonts.kanit(
                                            color: Colors.white),
                                      ),
                                      // ปุ่มสำหรับลบเวลา (Optional)
                                      GestureDetector(
                                        onTap: () => _removeTimeReminder(time),
                                        child: const Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            // ปุ่มเพิ่มเวลา จะแสดงเสมอ
                            GestureDetector(
                              onTap: _addTimeReminder,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5E6E6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add,
                                    color: Color(0xFF5A4330)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Reminders message',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC98993),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: messageController,
                            style: GoogleFonts.kanit(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Input Reminders message....',
                              hintStyle:
                                  GoogleFonts.kanit(color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton(
                            onPressed: _saveActivityDetail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF564843),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Complete',
                              style: GoogleFonts.kanit(
                                  fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
}
