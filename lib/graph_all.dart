import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/account.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/widgets/line_chart.dart';

class AllGraphScreen extends StatefulWidget {
  const AllGraphScreen({super.key});

  @override
  State<AllGraphScreen> createState() => _AllGraphScreenState();
}

class _AllGraphScreenState extends State<AllGraphScreen> {
  String selectedTab = 'Month';
  int _selectedIndex = 2;
  double? _percent;
  bool isLoadingPercent = true;

  List<DateTime> _dates = [];
  List<double> _percents = [];

  List<DateTime> _monthDates = [];
  List<double> _monthPercents = [];

  List<String> _yearLabels = [];
  List<double> _yearAverages = [];
  List<String> _labels = [];
  // List<double> _percents = [];

  void initState() {
    super.initState();
    _fetchOverallPercent('month'); // ค่าเริ่มต้นเป็นรายเดือน
  }

  Future<void> _fetchOverallPercent(String range) async {
    setState(() {
      isLoadingPercent = true;
      _labels = [];
      _percents = [];
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final idToken = await user.getIdToken();

      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityDetail/daily-overall-percent?range=$range',
      );

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'];

        _labels = [];
        _percents = [];

        for (var e in data) {
          final label = e['date']?.toString() ?? '';
          final percentValue = e['overall_percent'];
          double percent = 0.0;

          if (percentValue is num) {
            percent = percentValue.toDouble();
          } else if (percentValue is String) {
            percent = double.tryParse(percentValue) ?? 0.0;
          }

          if (label.isNotEmpty) {
            _labels.add(label);
            _percents.add(percent);
          }
        }

        _percent = _percents.isNotEmpty ? _percents.last : null;
      } else {
        print('Error fetching overall percent: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception fetching overall percent: $e');
    } finally {
      setState(() => isLoadingPercent = false);
    }
  }

  void _buildMonthSeries() {
    if (_dates.isEmpty) {
      _monthDates = [];
      _monthPercents = [];
      return;
    }
    final take = _dates.length > 30 ? 30 : _dates.length;
    _monthDates = _dates.sublist(_dates.length - take);
    _monthPercents = _percents.sublist(_percents.length - take);
  }

  void _buildYearSeries() {
    if (_dates.isEmpty) {
      _yearLabels = [];
      _yearAverages = [];
      return;
    }
    final take = _dates.length > 365 ? 365 : _dates.length;
    final lastDates = _dates.sublist(_dates.length - take);
    final lastPercents = _percents.sublist(_percents.length - take);

    // จัดเป็น label "DD/MM"
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
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCardContent(),
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

  Widget _buildHeader() {
    return Stack(
      children: [
        Column(
          children: [
            Container(
                color: const Color(0xFF564843),
                height: MediaQuery.of(context).padding.top + 80,
                width: double.infinity),
            const SizedBox(height: 60),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 30,
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: ClipOval(
              child: Image.asset('assets/images/logo.png',
                  width: 100, height: 100, fit: BoxFit.cover)),
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
                    style:
                        GoogleFonts.kanit(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAE3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabSelector(),
          const SizedBox(height: 16),
          isLoadingPercent
              ? const Center(child: CircularProgressIndicator())
              : LineChartWidget(values: _percents, labels: _labels),
          const SizedBox(height: 16),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return SizedBox(
      height: 36,
      child: Row(
        children: ['Month', 'Year'].map((tab) {
          final isSelected = selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedTab = tab);
                _fetchOverallPercent(
                  tab == 'Month' ? 'month' : 'year',
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFC98993)
                      : const Color(0xFFE6D2CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.kanit(
                    color: isSelected ? Colors.white : const Color(0xFF564843),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.brown.shade200.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 8)
        ],
      ),
      child: Text(
        isLoadingPercent
            ? 'กำลังโหลดเปอร์เซ็นต์... ⏳'
            : _percent != null
                ? 'คุณทำได้ ${_percent!.toStringAsFixed(1)}% 🎯\nสุดยอดมาก ๆ เลยค่ะ! คุณทำได้ดีแล้วนะ\nแต่ก็อย่าลืมสู้ต่อไป\nเชื่อในตัวเอง และก้าวไปให้ถึงเป้าหมายที่ตั้งไว้\nคุณเก่งมากจริง ๆ สู้ ๆ นะคะ🎉💖 '
                : 'ยังไม่มีข้อมูลเปอร์เซ็นต์ 😢',
        style: GoogleFonts.kanit(
            fontSize: 13,
            color: const Color(0xFF564843),
            fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }
}
