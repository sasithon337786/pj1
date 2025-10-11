import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/account.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:fl_chart/fl_chart.dart';

class AllGraphScreen extends StatefulWidget {
  const AllGraphScreen({
    super.key,
  });

  @override
  State<AllGraphScreen> createState() => _AllGraphScreenState();
}

class _AllGraphScreenState extends State<AllGraphScreen> {
  // ==== เลือกได้แค่ Month / Year ====
  String selectedTab = 'Month';

  int _selectedIndex = 2;
  double? _percent; // percent ล่าสุด (วันนี้/รายการท้ายสุด)
  bool isLoadingPercent = true;

  // -------- raw daily (จาก API) --------
  List<DateTime> _dates = [];
  List<double> _percents = [];

  // -------- ใช้สำหรับ "Month" (30 วันล่าสุด) --------
  List<DateTime> _monthDates = [];
  List<double> _monthPercents = [];

  // -------- ใช้สำหรับ "Year" (avg รายเดือน 12 เดือนล่าสุด) --------
  List<String> _yearLabels = []; // เช่น 01/25, 02/25 ...
  List<double> _yearAverages = [];
  Future<void> _fetchDailyOverallPercent() async {
    setState(() => isLoadingPercent = true);

    try {
      // ดึง Firebase ID token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final idToken = await user.getIdToken();

      // เรียก API
      final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/activityDetail/daily-overall-percent');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'];

        _dates = data.map<DateTime>((e) => DateTime.parse(e['date'])).toList();
        _percents = data
            .map<double>((e) => (e['overall_percent'] as num).toDouble())
            .toList();

        // เตรียมข้อมูลสำหรับ Month / Year
        _buildMonthSeries();
        _buildYearSeries();

        // percent ล่าสุด
        _percent = _percents.isNotEmpty ? _percents.last : null;
      } else {
        print('Error fetching data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception fetching data: $e');
    } finally {
      setState(() => isLoadingPercent = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDailyOverallPercent();
  }

  // ---------- 30 วันล่าสุดสำหรับแท็บ Month ----------
  void _buildMonthSeries() {
    if (_dates.isEmpty) {
      _monthDates = [];
      _monthPercents = [];
      return;
    }
    // เอา 30 จุดล่าสุดจากข้อมูลที่เรียงแล้ว
    final take = _dates.length > 30 ? 30 : _dates.length;
    _monthDates = _dates.sublist(_dates.length - take);
    _monthPercents = _percents.sublist(_percents.length - take);
  }

  // ---------- หาค่าเฉลี่ยรายเดือน 12 เดือนล่าสุดสำหรับแท็บ Year ----------
  void _buildYearSeries() {
    if (_dates.isEmpty) {
      _yearLabels = [];
      _yearAverages = [];
      return;
    }

    // เอา 365 วันล่าสุด
    final take = _dates.length > 365 ? 365 : _dates.length;
    final lastDates = _dates.sublist(_dates.length - take);
    final lastPercents = _percents.sublist(_percents.length - take);

    _yearLabels = lastDates
        .map((d) =>
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}')
        .toList();
    _yearAverages = lastPercents;
  }

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
        // อยู่หน้า Graph
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
            // ===== Header =====
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

            // ===== Card เนื้อหา =====
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
                  SizedBox(
                    height: 36,
                    child: Row(
                      children: ['Month', 'Year'].map((tab) {
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

                  const SizedBox(height: 16),

                  // ==== แสดงกราฟ (เฉพาะ Month / Year) ====
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: (selectedTab == 'Month')
                        ? _buildMonthLineChart()
                        : _buildYearLineChart(),
                  ),

                  const SizedBox(height: 16),

                  // ข้อความสรุป (ใช้ percent ล่าสุดจาก daily)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6F3), // สีชมพูอ่อนน่ารัก
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.shade200.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      isLoadingPercent
                          ? 'กำลังโหลดเปอร์เซ็นต์... ⏳'
                          : _percent != null
                              ? 'คุณทำได้ ${_percent!.toStringAsFixed(1)}% 🎯\n'
                                  'สุดยอดมาก ๆ เลยค่ะ!'
                                  'คุณทำได้ดีแล้วนะ\n แต่ก็อย่าลืมสู้ต่อไป\n'
                                  'เชื่อในตัวเอง และก้าวไปให้ถึงเป้าหมายที่ตั้งไว้\n'
                                  'คุณเก่งมากจริง ๆ สู้ ๆ นะคะ🎉💖 '
                              : 'ยังไม่มีข้อมูลเปอร์เซ็นต์ 😢',
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: const Color(0xFF564843),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),

      // ==== BottomNav (ตามเดิม) ====
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

  /// กราฟ Month: 30 วันล่าสุด (Line chart)
  /// กราฟ Month: 30 วันล่าสุด (Line chart)
  Widget _buildMonthLineChart() {
    if (_monthDates.isEmpty || _monthPercents.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('ยังไม่มีข้อมูลกราฟ (เดือน)')),
      );
    }

    final spots = List.generate(
      _monthPercents.length,
      (i) => FlSpot(i.toDouble(), _monthPercents[i]),
    );

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, _) => Text('${value.toInt()}%',
                    style: GoogleFonts.kanit(fontSize: 12)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (_monthDates.length / 6).clamp(1, 10).toDouble(),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _monthDates.length)
                    return const SizedBox.shrink();
                  final d = _monthDates[i];
                  return Transform.rotate(
                    angle: -0.6,
                    child: Text(
                      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
                      style: GoogleFonts.kanit(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF5A3E42),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.pink.shade400,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade100.withOpacity(0.4),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          gridData: FlGridData(show: true, drawVerticalLine: false),
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

  /// กราฟ Year: ค่าเฉลี่ยรายเดือนของ 12 เดือนล่าสุด (Line chart)
  Widget _buildYearLineChart() {
    if (_yearLabels.isEmpty || _yearAverages.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('ยังไม่มีข้อมูลกราฟ (ปี)')),
      );
    }

    final spots = List.generate(
      _yearAverages.length,
      (i) => FlSpot(i.toDouble(), _yearAverages[i]),
    );

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, _) => Text('${value.toInt()}%',
                    style: GoogleFonts.kanit(fontSize: 12)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (_yearLabels.length / 12).clamp(1, 50).toDouble(),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _yearLabels.length)
                    return const SizedBox.shrink();
                  return Transform.rotate(
                    angle: -0.6,
                    child: Text(_yearLabels[i],
                        style: GoogleFonts.kanit(fontSize: 11)),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF5A3E42),
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.pink.shade400,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade100.withOpacity(0.3),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          gridData: FlGridData(show: true, drawVerticalLine: false),
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
