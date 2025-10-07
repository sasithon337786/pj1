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

class UserGraphBarScreen extends StatefulWidget {
  final int actId;
  final String actName;
  final String actPic;
  final String? expectationText; // optional
  final int? actDetailId; // optional

  const UserGraphBarScreen({
    super.key,
    required this.actId,
    required this.actName,
    required this.actPic,
    this.expectationText,
    this.actDetailId,
  });

  @override
  State<UserGraphBarScreen> createState() => _UserGraphBarScreenState();
}

class _UserGraphBarScreenState extends State<UserGraphBarScreen> {
  int _selectedIndex = 2;
  double? _percent;
  bool isLoadingPercent = true;
  final TextEditingController expectationController = TextEditingController();

  // -------------------- ข้อมูลกราฟ --------------------
  List<String> _dateList = []; // YYYY-MM-DD
  List<double> _percentList = []; // แต่ละวัน

  @override
  void initState() {
    super.initState();
    expectationController.text = widget.expectationText ?? '';

    if (widget.actDetailId != null) {
      debugPrint('Calling fetchPercent for actDetailId: ${widget.actDetailId}');
      fetchPercent(widget.actDetailId!);
    } else {
      isLoadingPercent = false;
      debugPrint('No actDetailId provided, skipping fetchPercent');
    }
  }

  Future<void> fetchPercent(int actDetailId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      isLoadingPercent = true;
    });

    final idToken = await user.getIdToken(true);
    final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/dailyPercent?act_detail_id=$actDetailId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          setState(() {
            _dateList = data.map<String>((e) => e['date'].toString()).toList();
            _percentList = data.map<double>((e) {
              final val = e['percent'];
              if (val == null) return 0.0;
              if (val is num) return val.toDouble();
              if (val is String) return double.tryParse(val) ?? 0.0;
              return 0.0;
            }).toList();
            _percent = _percentList.isNotEmpty ? _percentList.last : 0;
            isLoadingPercent = false;
          });

          debugPrint('Fetched dates: $_dateList');
          debugPrint('Fetched percents: $_percentList');
          debugPrint('Latest percent: $_percent');
        } else {
          setState(() {
            _dateList = [];
            _percentList = [];
            _percent = null;
            isLoadingPercent = false;
          });
          debugPrint('No data returned from API.');
        }
      } else {
        debugPrint('Failed to fetch percent: ${response.body}');
        setState(() => isLoadingPercent = false);
      }
    } catch (e) {
      debugPrint('Error fetchPercent: $e');
      setState(() => isLoadingPercent = false);
    }
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

            // Card ข้อมูลกิจกรรม
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
                  // รูป + ชื่อกิจกรรม
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.actPic,
                          width: 30,
                          height: 30,
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
                            fontSize: 25,
                            color: const Color(0xFF564843),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // กราฟเฉพาะ Week
                  _buildBarChart(),

                  const SizedBox(height: 16),

                  // ข้อความสรุป
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAD9D4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isLoadingPercent
                          ? 'กำลังโหลดเปอร์เซ็นต์...'
                          : _percent != null
                              ? 'คุณทำได้ ${_percent!.toStringAsFixed(1)}% จากเป้าหมายที่ตั้งไว้เก่งมากๆแล้วนะคะ🎯🏆ในวันต่อๆไปก็สู้ๆนะคะ Do your best!🌟🙌❤️'
                              : 'ยังไม่มีข้อมูลเปอร์เซ็นต์',
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
    if (_dateList.isEmpty || _percentList.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('ยังไม่มีข้อมูลกราฟ')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.shade200.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'สรุปผลรายสัปดาห์',
            style: GoogleFonts.kanit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A3E42),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.brown.shade100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}%',
                        style: GoogleFonts.kanit(
                          fontSize: 12,
                          color: Colors.brown.shade700,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= _dateList.length)
                          return const SizedBox.shrink();
                        final parsedDate = DateTime.tryParse(_dateList[index]);
                        final label =
                            "${parsedDate?.day.toString().padLeft(2, '0')}/${parsedDate?.month.toString().padLeft(2, '0')}";
                        return Text(
                          label,
                          style: GoogleFonts.kanit(
                            fontSize: 11,
                            color: Colors.brown.shade700,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < _percentList.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _percentList[i],
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4A5A5), Color(0xFF8C6E63)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
