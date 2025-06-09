import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/doing_activity.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class ChooseactivityPage extends StatefulWidget {
  @override
  State<ChooseactivityPage> createState() => _DrinkWaterGoalPageState();
}

class _DrinkWaterGoalPageState extends State<ChooseactivityPage> {
  TimeOfDay selectedTime = TimeOfDay(hour: 10, minute: 30);

  TextEditingController goalController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  bool isWeekSelected = true; // เริ่มต้นเลือก Week
  int _selectedIndex = 0;
  String selectedUnit = 'Type';
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime)
      setState(() {
        selectedTime = picked;
      });
  }

  void _showUnitPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Color(0xFFE6D2CD),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เลือกประเภทหน่วย',
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  color: Color(0xFF5A4330),
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: ['ml', 'm', 'km', 'hr', 'min', 'cal'].map((unit) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedUnit = unit;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedUnit == unit
                            ? Color(0xFF564843)
                            : Color(0xFFC98993),
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: SingleChildScrollView(
        child: Column(
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
                    SizedBox(height: 60),
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
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFE6D2CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drink Water',
                    style: GoogleFonts.kanit(
                      fontSize: 22,
                      color: Color(0xFF564843),
                      // fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Goal & Goal Period',
                    style: GoogleFonts.kanit(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF564843),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: goalController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.kanit(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'add...',
                              hintStyle:
                                  GoogleFonts.kanit(color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap:
                            _showUnitPicker, // เปลี่ยนเป็นเรียก _showUnitPicker() อันใหม่นี้
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFFEFEAE3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$selectedUnit ',
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              color: Color(0xFFC98993),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isWeekSelected = false; // เลือก Day
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isWeekSelected
                                    ? Color(0xFFF5E6E6)
                                    : Color(0xFFC98993),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Day',
                                style: GoogleFonts.kanit(
                                  color: isWeekSelected
                                      ? Color(0xFF5A4330)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isWeekSelected = true; // เลือก Week
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isWeekSelected
                                    ? Color(0xFFC98993)
                                    : Color(0xFFF5E6E6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Week',
                                style: GoogleFonts.kanit(
                                  color: isWeekSelected
                                      ? Colors.white
                                      : Color(0xFF5A4330),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Reminders',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFC98993),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Day',
                      style: GoogleFonts.kanit(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Time reminders',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Color(0xFF564843),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${selectedTime.format(context)}',
                          style: GoogleFonts.kanit(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5E6E6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add, color: Color(0xFF5A4330)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Reminders message',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFC98993),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: messageController,
                      style: GoogleFonts.kanit(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Input Reminders message....',
                        hintStyle: GoogleFonts.kanit(color: Colors.white70),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DoingActivity()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF564843),
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 14),
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
                  )
                ],
              ),
            ),
          ],
        ),
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
