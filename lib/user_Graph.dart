import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class UserGraphBarScreen extends StatefulWidget {
  final int actId;
  final String actName;
  final String actPic;

  const UserGraphBarScreen({
    super.key,
    required this.actId,
    required this.actName,
    required this.actPic,
  });

  @override
  State<UserGraphBarScreen> createState() => _UserGraphBarScreenState();
}

class _UserGraphBarScreenState extends State<UserGraphBarScreen> {
  String selectedTab = 'Week'; // Week = Bar, Month/Year = Line
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Targetpage()));
        break;
      case 2:
        // อยู่หน้า Graph แล้ว
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AccountPage()));
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
                    child: Image.asset('assets/images/logo.png',
                        width: 100, height: 100, fit: BoxFit.cover),
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
                        Text('ย้อนกลับ',
                            style: GoogleFonts.kanit(
                                color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card เนื้อหา
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEAE3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // บรรทัดที่ 1: รูป + ชื่อกิจกรรม (ให้ชื่อหด/ตัดด้วย ellipsis)
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.actPic,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              color: Color(0xFF564843)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.actName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            color: const Color(0xFF564843),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // บรรทัดที่ 2: แท็บเลื่อนแนวนอน (ไม่ตกขอบอีก)
                  SizedBox(
                    height: 36, // ความสูงพอดีปุ่มสวย ๆ
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Week', 'Month', 'Year'].map((tab) {
                          final isSelected = selectedTab == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => selectedTab = tab),
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
                    ),
                  ),

                  const SizedBox(height: 16),

                  // === กราฟสลับตามแท็บ ===
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: selectedTab == 'Week'
                        ? _buildBarChart()
                        : _buildLineChart(),
                  ),

                  const SizedBox(height: 16),

                  // ข้อความสรุป (ตัวอย่าง)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6D2CD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      selectedTab == 'Week'
                          ? 'สัปดาห์นี้คุณทำ "${widget.actName}" ได้ 82% จากเป้าหมายที่ตั้งไว้\nสู้ ๆ นะคะ ✨'
                          : 'ช่วง${selectedTab.toLowerCase()}นี้คุณทำ "${widget.actName}" ได้ 87% จากเป้าหมายที่ตั้งไว้\nดีมากเลย! รักษาความสม่ำเสมอไว้นะ 💖',
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

  // ---------------- Widgets กราฟ ----------------

  Widget _buildBarChart() {
    return SizedBox(
      key: const ValueKey('bar'),
      height: 250,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text('${value.toInt()}%',
                    style: GoogleFonts.kanit(fontSize: 12)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text('${value.toInt()}',
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
    );
  }

  Widget _buildLineChart() {
    // ตัวอย่างข้อมูล line; ถ้าอยากแยก Month/Year จริง ๆ ก็แตกข้อมูลตาม selectedTab ได้
    final spots = selectedTab == 'Month'
        ? const [
            FlSpot(1, 10),
            FlSpot(2, 20),
            FlSpot(3, 40),
            FlSpot(4, 80),
            FlSpot(5, 60),
            FlSpot(6, 60),
            FlSpot(7, 70),
            FlSpot(8, 65),
            FlSpot(9, 75),
            FlSpot(10, 50),
          ]
        : const [
            FlSpot(1, 30),
            FlSpot(2, 45),
            FlSpot(3, 50),
            FlSpot(4, 60),
            FlSpot(5, 55),
            FlSpot(6, 70),
            FlSpot(7, 65),
            FlSpot(8, 75),
            FlSpot(9, 78),
            FlSpot(10, 80),
          ];

    return SizedBox(
      key: const ValueKey('line'),
      height: 250,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text('${value.toInt()}%',
                    style: GoogleFonts.kanit(fontSize: 12)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text('${value.toInt()}',
                    style: GoogleFonts.kanit(fontSize: 12)),
              ),
            ),
          ),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF5A3E42),
              barWidth: 3,
              dotData: FlDotData(show: false),
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
        ),
      ),
    );
  }
}
