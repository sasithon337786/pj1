import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:pj1/user_grapline.dart';

class UserGraphBarScreen extends StatefulWidget {
  const UserGraphBarScreen({Key? key}) : super(key: key);

  @override
  State<UserGraphBarScreen> createState() => _UserGraphBarScreenState();
}

class _UserGraphBarScreenState extends State<UserGraphBarScreen> {
  String selectedTab = 'Week';
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
        break;
      case 1:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const Targetpage()));
        break;
      case 2:
        // อยู่หน้า Graph อยู่แล้ว
        break;
      case 3:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const AccountPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
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

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEAE3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'Drink Water',
                      style: GoogleFonts.kanit(
                          fontSize: 20, color: const Color(0xFF564843)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Week', 'Month', 'Year'].map((tab) {
                      final isSelected = selectedTab == tab;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTab = tab;
                            });

                            if (tab == 'Month' || tab == 'Year') {
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const UserGraphlineScreen()),
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFC98993)
                                  : const Color(0xFFE6D2CD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tab,
                              style: GoogleFonts.kanit(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF564843),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, _) => Text(
                                  '${value.toInt()}%',
                                  style: GoogleFonts.kanit(fontSize: 12)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) => Text(
                                  '${value.toInt()}',
                                  style: GoogleFonts.kanit(fontSize: 12)),
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 1; i <= 10; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: (i * 7) % 100,
                                  color: const Color(0xFF5A3E42),
                                  width: 16,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            ),
                        ],
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(),
                            left: BorderSide(),
                            right: BorderSide.none,
                            top: BorderSide.none,
                          ),
                        ),
                        maxY: 100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6D2CD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ใน 1 เดือนนี้คุณทำ Activity Drink Water ได้ 87% จากเป้าหมายที่คุณตั้งไว้\nขอให้คุณมีความสุขในทุกๆวัน',
                      style: GoogleFonts.kanit(
                          fontSize: 16, color: const Color(0xFF564843)),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
