import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/calendar_page.dart';
import 'package:pj1/chooseactivity.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/set_time.dart';
import 'package:pj1/target.dart';

class DoingActivity extends StatefulWidget {
  const DoingActivity({super.key});

  @override
  State<DoingActivity> createState() => _DoingActivityState();
}

class _DoingActivityState extends State<DoingActivity> {
  int _selectedIndex = 0;
  TextEditingController categoryController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: Stack(
        children: [
          Column(
            children: [
              // Top bar
              Container(
                color: const Color(0xFF564843),
                height: MediaQuery.of(context).padding.top + 80,
                width: double.infinity,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF564843),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const CalendarPage()),
                                  );
                                },
                                icon: const Icon(Icons.calendar_month,
                                    color: Colors.white, size: 16),
                                label: Text(
                                  'ปฏิทินความสำเร็จ',
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Image.asset(
                                  'assets/icons/profile.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Activity',
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12), // ระยะห่างหลังหัวข้อ
                          ],
                        ),
                      ),
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: const [
                          TaskCard(
                            iconPath: 'assets/images/raindrops.png',
                            label: 'Drink Water',
                            statusText: '300 / ml',
                          ),
                          TaskCard(
                            iconPath: 'assets/images/eat.png',
                            label: 'Eat',
                            statusText: 'Complete',
                          ),
                          TaskCard(
                            iconPath: 'assets/images/meditation.png',
                            label: 'Meditation',
                            statusText: 'Complete',
                          ),
                          TaskCard(
                            iconPath: 'assets/images/yoga.png',
                            label: 'Yoga',
                            statusText: '0 / min',
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      // Custom button
                    ],
                  ),
                ),
              ),
            ],
          ),
          // โลโก้ Positioned เหมือนหน้า HomePage
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
          // ปุ่มย้อนกลับ
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

class CategoryIcon extends StatelessWidget {
  final String icon; 
  final String label;

  const CategoryIcon({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE6D2C0),
          radius: 24,
          child: Image.asset(
            icon,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.kanit(
              fontSize: 12, color: Colors.white), 
        ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  final String iconPath;
  final String label;
  final String statusText;

  const TaskCard({
    Key? key,
    required this.iconPath,
    required this.label,
    required this.statusText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF3E1E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Image.asset(
              iconPath,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.kanit(fontSize: 20, color: Color(0xFFC98993)),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF564843),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText,
            style: GoogleFonts.kanit(color: Colors.white, fontSize: 14),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CountdownPage()),
          );
        },
      ),
    );
  }
}
