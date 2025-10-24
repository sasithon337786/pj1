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
  // ====== Loading states ======
  bool isLoadingMonth = true;
  bool isLoadingYear = true;

  // ====== Data for Month ======
  List<String> _monthLabels = [];
  List<double> _monthPercents = [];
  double? _latestMonthPercent;

  // ====== Data for Year ======
  List<String> _yearLabels = [];
  List<double> _yearPercents = [];
  double? _latestYearPercent;

  // (ถ้าจะใช้ bottom nav ในอนาคต เก็บไว้ได้)
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    // โหลดทั้ง "เดือน" และ "ปี" พร้อมกัน
    _fetchOverallPercent('month');
    _fetchOverallPercent('year');
  }

  Future<void> _fetchOverallPercent(String range) async {
    // อัพเดตสถานะโหลดเฉพาะชุดที่เกี่ยวข้อง
    if (range == 'month') {
      setState(() {
        isLoadingMonth = true;
        _monthLabels = [];
        _monthPercents = [];
      });
    } else {
      setState(() {
        isLoadingYear = true;
        _yearLabels = [];
        _yearPercents = [];
      });
    }

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
        final List data = body['data'] ?? [];

        final labels = <String>[];
        final percents = <double>[];

        for (var e in data) {
          final label = (e['date'] ?? '').toString();
          final percentValue = e['overall_percent'];
          double percent = 0.0;

          if (percentValue is num) {
            percent = percentValue.toDouble();
          } else if (percentValue is String) {
            percent = double.tryParse(percentValue) ?? 0.0;
          }

          if (label.isNotEmpty) {
            labels.add(label);
            percents.add(percent);
          }
        }

        setState(() {
          if (range == 'month') {
            _monthLabels = labels;
            _monthPercents = percents;
            _latestMonthPercent =
                _monthPercents.isNotEmpty ? _monthPercents.last : null;
          } else {
            _yearLabels = labels;
            _yearPercents = percents;
            _latestYearPercent =
                _yearPercents.isNotEmpty ? _yearPercents.last : null;
          }
        });
      } else {
        debugPrint(
            'Error fetching overall percent ($range): ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception fetching overall percent ($range): $e');
    } finally {
      setState(() {
        if (range == 'month') {
          isLoadingMonth = false;
        } else {
          isLoadingYear = false;
        }
      });
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
            // ====== การ์ดกราฟ "รายเดือน" ======
            _buildGraphCard(
              title: 'กราฟรายเดือน (30 วันล่าสุด)',
              isLoading: isLoadingMonth,
              labels: _monthLabels,
              values: _monthPercents,
              latestPercent: _latestMonthPercent,
            ),
            const SizedBox(height: 16),
            // ====== การ์ดกราฟ "รายปี" ======
            _buildGraphCard(
              title: 'กราฟรายปี (ย้อนหลัง 365 วัน)',
              isLoading: isLoadingYear,
              labels: _yearLabels,
              values: _yearPercents,
              latestPercent: _latestYearPercent,
            ),
            const SizedBox(height: 24),
          ],
        ),
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
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'ย้อนกลับ',
                  style: GoogleFonts.kanit(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphCard({
    required String title,
    required bool isLoading,
    required List<String> labels,
    required List<double> values,
    required double? latestPercent,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAE3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: GoogleFonts.kanit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF564843),
            ),
          ),
          const SizedBox(height: 12),

          // Chart
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6F3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.shade200.withOpacity(0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: SizedBox(
              height: 220,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (values.isNotEmpty && labels.isNotEmpty)
                      ? LineChartWidget(values: values, labels: labels)
                      : Center(
                          child: Text(
                            'ยังไม่มีข้อมูลกราฟ',
                            style: GoogleFonts.kanit(
                              color: const Color(0xFF564843),
                              fontSize: 14,
                            ),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 12),

          // Summary
          _buildSummary(latestPercent: latestPercent),
        ],
      ),
    );
  }

  Widget _buildSummary({required double? latestPercent}) {
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
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        (latestPercent == null)
            ? 'ยังไม่มีข้อมูลเปอร์เซ็นต์ 😢'
            : 'คุณทำได้ ${latestPercent.toStringAsFixed(1)}% 🎯\nสุดยอดมาก ๆ เลยค่ะ! คุณทำได้ดีแล้วนะ\nแต่ก็อย่าลืมสู้ต่อไป\nเชื่อในตัวเอง และก้าวไปให้ถึงเป้าหมายที่ตั้งไว้\nคุณเก่งมากจริง ๆ สู้ ๆ นะคะ🎉💖',
        style: GoogleFonts.kanit(
          fontSize: 13,
          color: const Color(0xFF564843),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
