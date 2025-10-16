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
import 'package:pj1/widgets/weekly_bar_chart.dart';

class UserGraphBarScreen extends StatefulWidget {
  final int actId;
  final String actName;
  final String actPic;
  final String? expectationText;
  final int? actDetailId;

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
  double? _percent; // แท่งล่าสุด (วันนี้ตาม local)
  bool isLoadingPercent = true;
  final TextEditingController expectationController = TextEditingController();

  // raw จาก API (debug)
  List<String> _dateList = []; // "YYYY-MM-DD" หรือ ISO
  // ชุดสำหรับวาดกราฟ (7 วันล่าสุดแบบต่อเนื่อง)
  List<double> _percentList = []; // ยาว 7
  List<String> _barLabels = []; // ยาว 7 รูปแบบ dd/MM

  @override
  void initState() {
    super.initState();
    expectationController.text = widget.expectationText ?? '';
    if (widget.actDetailId != null) {
      fetchPercent(widget.actDetailId!);
    } else {
      isLoadingPercent = false;
      debugPrint('No actDetailId provided, skipping fetchPercent');
    }
  }

  Future<void> fetchPercent(int actDetailId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => isLoadingPercent = true);

    final idToken = await user.getIdToken(true);
    print(idToken);
    final url = Uri.parse(
      '${ApiEndpoints.baseUrl}/api/activityHistory/dailyPercent?act_detail_id=$actDetailId',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          debugPrint('Sample row: ${data.first}');

          final dates = data.map<String>((e) => e['date'].toString()).toList();
          final percents = data.map<double>((e) {
            final v = e['percent'];
            if (v == null) return 0.0;
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? 0.0;
            return 0.0;
          }).toList();

          _dateList = dates;
          _buildLast7DaysSeries(dates, percents);

          setState(() => isLoadingPercent = false);

          debugPrint('Bar labels (7d): $_barLabels');
          debugPrint('Percents (7d): $_percentList');
          debugPrint('Latest percent (today): $_percent');
        } else {
          setState(() {
            _dateList = [];
            _percentList = [];
            _barLabels = [];
            _percent = null;
            isLoadingPercent = false;
          });
          debugPrint('No data returned from API.');
        }
      } else {
        debugPrint('Failed to fetch percent: ${response.body}');
        setState(() => isLoadingPercent = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('ดึงข้อมูลไม่สำเร็จ (${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetchPercent: $e');
      setState(() => isLoadingPercent = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
        );
      }
    }
  }

  /// สร้างข้อมูล 7 วันล่าสุดแบบต่อเนื่อง:
  /// - รองรับทั้ง "YYYY-MM-DD" และ ISO "YYYY-MM-DDTHH:mm:ssZ"
  /// - ถ้าเป็น ISO ให้ parse แล้ว .toLocal() เพื่อได้ “วันที่ตามเครื่อง”
  void _buildLast7DaysSeries(List<String> apiDates, List<double> apiPercents) {
    String _toLocalYmdKey(String s) {
      final t = s.trim();
      if (t.isEmpty) return '';

      // เป็นรูปแบบ ISO (มี 'T')
      if (t.contains('T')) {
        try {
          final dt = DateTime.parse(t).toLocal(); // UTC -> Local
          final y = dt.year.toString().padLeft(4, '0');
          final m = dt.month.toString().padLeft(2, '0');
          final d = dt.day.toString().padLeft(2, '0');
          return '$y-$m-$d';
        } catch (_) {
          // ถ้า parse ไม่ได้ ค่อย fallback ด้านล่าง
        }
      }

      // เป็น 'YYYY-MM-DD' เดิม
      final base = t.length >= 10 ? t.substring(0, 10) : t;
      final parts = base.split('-');
      if (parts.length == 3 &&
          int.tryParse(parts[0]) != null &&
          int.tryParse(parts[1]) != null &&
          int.tryParse(parts[2]) != null) {
        final y = parts[0].padLeft(4, '0');
        final m = parts[1].padLeft(2, '0');
        final d = parts[2].padLeft(2, '0');
        return '$y-$m-$d';
      }
      return '';
    }

    // 1) map (YYYY-MM-DD local) -> percent (เอาค่าสุดท้ายของวันนั้น)
    final Map<String, double> day2pct = {};
    for (var i = 0; i < apiDates.length; i++) {
      final key = _toLocalYmdKey(apiDates[i]);
      if (key.isEmpty) continue;
      day2pct[key] = apiPercents[i].clamp(0.0, 100.0);
    }

    if (day2pct.isEmpty) {
      _barLabels = [];
      _percentList = [];
      _percent = null;
      return;
    }

    // 2) เอาวันล่าสุด (ตาม local)
    final allKeys = day2pct.keys.toList()..sort(); // YYYY-MM-DD sortable
    final anchorKey = allKeys.last;

    // 3) สร้างช่วง 7 วัน: anchor-6 ... anchor
    DateTime _ymdToDate(String ymd) {
      final p = ymd.split('-');
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    }

    final anchorDate = _ymdToDate(anchorKey);
    final days =
        List.generate(7, (i) => anchorDate.subtract(Duration(days: 6 - i)));

    // 4) ทำ labels (dd/MM) และค่า (ไม่มี = 0)
    final labels = <String>[];
    final vals = <double>[];
    for (final d in days) {
      final key = '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      labels.add('${key.substring(8, 10)}/${key.substring(5, 7)}');
      vals.add((day2pct[key] ?? 0.0).clamp(0.0, 100.0));
    }

    _barLabels = labels;
    _percentList = vals;
    _percent = _percentList.isNotEmpty ? _percentList.last : null;
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

            // Card ข้อมูลกิจกรรม + กราฟ
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
                  WeeklyBarChart(
                    isLoading: isLoadingPercent,
                    percentList: _percentList,
                    barLabels: _barLabels,
                  ),
                  const SizedBox(height: 16),

                  // Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6F3),
                      borderRadius: BorderRadius.circular(20),
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
                          ? 'กำลังโหลดเปอร์เซ็นต์...'
                          : _percent != null
                              ? 'คุณทำได้ ${_percent!.toStringAsFixed(1)}% จากเป้าหมาย 🎯\nเก่งมากๆ แล้วนะคะ! ในวันต่อๆ ไปก็สู้ๆ นะคะ \nDo your best!💪🌟🙌❤️'
                              : 'ยังไม่มีข้อมูลเปอร์เซ็นต์',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        color: const Color(0xFF5A3E42),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
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

  // ---------------- Widgets กราฟ ----------------

}
