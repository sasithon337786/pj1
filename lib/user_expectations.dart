import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pj1/account.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class ExpectationResultScreen extends StatefulWidget {
  final int actId;
  final String expectationText;
  final int actDetailId;

  const ExpectationResultScreen({
    super.key,
    required this.actId,
    required this.expectationText,
    required this.actDetailId,
  });

  @override
  State<ExpectationResultScreen> createState() =>
      _ExpectationResultScreenState();
}

class _ExpectationResultScreenState extends State<ExpectationResultScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isFetching = false; // กันกดรีเฟรชรัวๆ
  double? _percent;

  final TextEditingController expectationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // แสดงค่าที่ส่งมาทันที
    expectationController.text = widget.expectationText;
    // โหลดเปอร์เซ็นต์ + (ถ้าอยากดึง expectation จากเซิร์ฟเวอร์ ให้เปิดใช้ _fetchExpectation())
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchPercent(widget.actDetailId),
      // _fetchExpectation(), // ถ้าต้องดึง expectation จาก backend ให้ uncomment
    ]);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _fetchExpectation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final idToken = await user.getIdToken(true);
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/expuser/getuidex?uid=${user.uid}&act_id=${widget.actId}',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final text = data.isNotEmpty ? (data[0]['user_exp'] ?? '') : '';
        if (!mounted) return;
        setState(() {
          expectationController.text = text.toString();
        });
      } else {
        debugPrint("fetchExpectation ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("fetchExpectation error: $e");
    }
  }

  Future<void> _fetchPercent(int actDetailId) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken(true);
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/getTodaySum?act_detail_id=$actDetailId',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // กันกรณี percent เป็น int/String/null
        double parsed = 0.0;
        final p = (data is Map) ? data['percent'] : null;
        if (p is num) {
          parsed = p.toDouble();
        } else if (p is String) {
          parsed = double.tryParse(p) ?? 0.0;
        }

        if (!mounted) return;
        setState(() {
          _percent = parsed.clamp(0.0, 100.0);
        });
        debugPrint('Percent: $_percent');
      } else {
        debugPrint('fetchPercent ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('fetchPercent error: $e');
    } finally {
      _isFetching = false;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // ใช้ pushReplacement เพื่อลดการซ้อนของ route
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Targetpage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Graphpage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountPage()),
        );
        break;
    }
  }

  @override
  void dispose() {
    expectationController.dispose();
    super.dispose();
  }

  String getMotivationMessage(double percent) {
    if (percent >= 100) {
      return "สุดยอด! วันนี้ทำได้ตามเป้าหมายที่ตั้งไว้แล้ว 🎉";
    } else if (percent >= 80) {
      return "เยี่ยมมาก! ใกล้ถึงเป้าหมายแล้วเพิ่มอีกนิดนะ 💪";
    } else if (percent >= 50) {
      return "กำลังไปได้ดีเลย อย่าลืมทำต่อให้ถึงเป้าหมายนะ 😊";
    } else {
      return "ไม่เป็นไรนะ ถือว่าเริ่มต้น ทำไปเรื่อยๆนะคะ Don’t give up! 🌱";
    }
  }

  @override
  Widget build(BuildContext context) {
    // ถ้าชอบ Noto Sans Thai เปลี่ยนเป็น GoogleFonts.notoSansThai() ได้เลย
    final textTheme = GoogleFonts.kanit();

    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, textTheme)),
            SliverToBoxAdapter(child: const SizedBox(height: 30)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _buildExpectationCard(textTheme),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _buildPercentCard(textTheme),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE6D2CD),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
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

  Widget _buildHeader(BuildContext context, TextStyle textTheme) {
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
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'ย้อนกลับ',
                  style: textTheme.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpectationCard(TextStyle textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAE3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/icons/winking-face.png',
                  width: 30, height: 30),
              const SizedBox(width: 8),
              Text(
                'EXPECTATIONS',
                style: textTheme.copyWith(
                  fontSize: 18,
                  color: const Color(0xFF5B4436),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEAE3),
              border: Border.all(color: const Color(0xFFC98993), width: 1.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite, color: Color(0xFFC98993), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: _isLoading
                      ? _buildShimmerLine(height: 18)
                      : Text(
                          expectationController.text.isNotEmpty
                              ? expectationController.text
                              : 'ไม่มีข้อมูลความคาดหวัง',
                          style: textTheme.copyWith(
                            fontSize: 15,
                            color: const Color(0xFF5B4436),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentCard(TextStyle textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAE3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/icons/persent.png', width: 30, height: 30),
              const SizedBox(width: 8),
              Text(
                'เปอร์เซ็นต์ความคาดหวังของคุณ',
                style: textTheme.copyWith(
                  fontSize: 18,
                  color: const Color(0xFF5B4436),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isLoading
              ? _buildShimmerLine(width: 80, height: 24)
              : Text(
                  _percent != null
                      ? '${_percent!.toStringAsFixed(1)}%'
                      : 'รอคำนวณ...',
                  style: textTheme.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFC98993),
                  ),
                ),
          const SizedBox(height: 15),
          Text(
            _percent != null
                ? getMotivationMessage(_percent!)
                : 'กำลังคำนวณผลลัพธ์...',
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 17,
              color: const Color(0xFF5B4436),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // shimmer line ง่ายๆ ไม่พึ่งแพ็กเกจ
  Widget _buildShimmerLine(
      {double width = double.infinity, double height = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAD9D4),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
