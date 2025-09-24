import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ ใช้ดึง idToken

class CountdownPage extends StatefulWidget {
  final String actName; // ชื่อกิจกรรมจริง
  final String unit; // หน่วย (วินาที/นาที/ชั่วโมง หรือ sec/min/hr)
  final String actDetailId; // ไอดี activity_detail
  final String? goal; // เป้าหมายตั้งต้น (optional)
  final String? imageSrc; // รูปกิจกรรม

  const CountdownPage({
    super.key,
    required this.actName,
    required this.unit,
    required this.actDetailId,
    this.goal,
    this.imageSrc,
  });

  @override
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  // เวลารอบนี้ (เดินหน้า)
  Duration _elapsed = Duration.zero;
  late Duration _target;
  Timer? _timer;
  bool isRunning = false;
  int _selectedIndex = 0;

  // ค่าในฐานข้อมูล
  double _serverCurrent = 0.0;
  double _goalAmount = 0.0;
  bool _loading = true;
  bool _saving = false;

  // ✅ แนบ Firebase ID token ทุกครั้ง
  Future<Map<String, String>> _authHeaders() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  @override
  void initState() {
    super.initState();
    _goalAmount =
        double.tryParse(widget.goal ?? '') ?? 20.0; // ดีฟอลต์ 20 "นาที"
    _target = _durationFromUnit(widget.unit, _goalAmount);
    _fetchDetail(widget.actDetailId); // ดึง goal/current ล่าสุดจากหลังบ้าน
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- REST ----------
  // ดึงข้อมูล activity_detail ล่าสุด
  Future<void> _fetchDetail(String actDetailId) async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityDetail/getActivityDetailById?act_detail_id=${Uri.encodeComponent(widget.actDetailId)}',
      );
      final res = await http.get(url, headers: await _authHeaders());

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // อัปเดต goal
        final g = data['goal'];
        if (g is num)
          _goalAmount = g.toDouble();
        else if (g is String) _goalAmount = double.tryParse(g) ?? _goalAmount;

        // อัปเดต current_value
        final cv = data['current_value'];
        if (cv is num)
          _serverCurrent = cv.toDouble();
        else if (cv is String)
          _serverCurrent = double.tryParse(cv) ?? _serverCurrent;

        _target = _durationFromUnit(widget.unit, _goalAmount);
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('สิทธิ์ไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่')),
          );
        }
      } else {
        debugPrint('fetch detail failed: ${res.statusCode} ${res.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ (${res.statusCode})')),
          );
        }
      }
    } catch (e) {
      debugPrint('fetch detail error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persistIncrease(double amountToAdd) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityDetail/increaseCurrentValue?act_detail_id=${Uri.encodeComponent(widget.actDetailId)}',
      );

      final res = await http.post(
        url,
        headers: await _authHeaders(),
        body: jsonEncode({'amount': amountToAdd}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // อัปเดต current_value
        final cv = data['current_value'];
        if (cv is num)
          _serverCurrent = cv.toDouble();
        else if (cv is String)
          _serverCurrent = double.tryParse(cv) ?? _serverCurrent;

        // อัปเดต goal
        final g = data['goal'];
        if (g != null) {
          if (g is num)
            _goalAmount = g.toDouble();
          else if (g is String) _goalAmount = double.tryParse(g) ?? _goalAmount;
        }

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกเวลาสำเร็จ')),
          );
        }
      } else if (res.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบรายการกิจกรรม')),
          );
        }
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('สิทธิ์ไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่')),
          );
        }
      } else {
        debugPrint('increase failed: ${res.statusCode} ${res.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง')),
          );
        }
      }
    } catch (e) {
      debugPrint('increase error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  // ---------------------------

  Duration _durationFromUnit(String unitRaw, double goalVal) {
    final u = unitRaw.trim().toLowerCase();
    if (u == 'วินาที' ||
        u == 'sec' ||
        u == 'secs' ||
        u == 'second' ||
        u == 'seconds') {
      return Duration(seconds: goalVal.round());
    }
    if (u == 'นาที' ||
        u == 'min' ||
        u == 'mins' ||
        u == 'minute' ||
        u == 'minutes') {
      return Duration(seconds: (goalVal * 60).round());
    }
    if (u == 'ชั่วโมง' ||
        u == 'hr' ||
        u == 'hrs' ||
        u == 'hour' ||
        u == 'hours') {
      return Duration(seconds: (goalVal * 3600).round());
    }
    return Duration(seconds: (goalVal * 60).round());
  }

  double _secondsToUnit(int seconds) {
    final u = widget.unit.trim().toLowerCase();
    if (u == 'วินาที' ||
        u == 'sec' ||
        u == 'secs' ||
        u == 'second' ||
        u == 'seconds') {
      return seconds.toDouble();
    }
    if (u == 'นาที' ||
        u == 'min' ||
        u == 'mins' ||
        u == 'minute' ||
        u == 'minutes') {
      return seconds / 60.0;
    }
    if (u == 'ชั่วโมง' ||
        u == 'hr' ||
        u == 'hrs' ||
        u == 'hour' ||
        u == 'hours') {
      return seconds / 3600.0;
    }
    return seconds / 60.0;
  }

  void startTimer() {
    _timer?.cancel();
    isRunning = true;
    setState(() {});

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_goalAmount > 0 && _serverCurrent >= _goalAmount) {
        _timer?.cancel();
        isRunning = false;
        setState(() {});
        _showGoalReachedDialog();
        return;
      }

      setState(() {
        _elapsed += const Duration(seconds: 1);
      });

      final sessionAmount = _secondsToUnit(_elapsed.inSeconds);
      final remaining =
          (_goalAmount > 0) ? (_goalAmount - _serverCurrent) : double.infinity;

      if (sessionAmount >= remaining && remaining.isFinite) {
        _timer?.cancel();
        isRunning = false;
        setState(() {});
        _handleSaveAndGoal(remaining);
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    isRunning = false;

    final sessionAmount = _secondsToUnit(_elapsed.inSeconds);
    final remaining =
        (_goalAmount > 0) ? (_goalAmount - _serverCurrent) : double.infinity;
    final toAdd = remaining.isFinite
        ? (sessionAmount.clamp(0.0, remaining)).toDouble()
        : sessionAmount;

    setState(() {});
    _saveSessionAndReset(toAdd);
  }

  void _handleSaveAndGoal(double remaining) async {
    await _persistIncrease(remaining);
    _elapsed = Duration.zero;
    if (!mounted) return;
    setState(() {});
    _showGoalReachedDialog();
  }

  void _saveSessionAndReset(double toAdd) async {
    if (toAdd > 0) {
      await _persistIncrease(toAdd);
    }
    _elapsed = Duration.zero;
    if (mounted) setState(() {});
  }

  void selectNewTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _target.inHours.clamp(0, 23),
        minute: _target.inMinutes.remainder(60),
      ),
    );

    if (picked != null) {
      final asSeconds = picked.hour * 3600 + picked.minute * 60;
      setState(() {
        _target = Duration(seconds: asSeconds);
        _elapsed = Duration.zero;
        isRunning = false;
      });
      _timer?.cancel();
    }
  }

  void _resetSession() {
    // รีเซ็ตเวลาที่นับใน "รอบนี้" เท่านั้น ไม่ยุ่งค่าที่บันทึกใน DB
    setState(() {
      _elapsed = Duration.zero;
    });

    // ถ้าอยากให้รีเซ็ตแล้วหยุดจับเวลาด้วย ให้ยกเลิกคอมเมนต์ 2 บรรทัดล่างนี้
    // _timer?.cancel();
    // isRunning = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('รีเซ็ตเวลารอบนี้แล้ว')),
    );
  }

  String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Targetpage()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Graphpage()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AccountPage()));
        break;
    }
  }

  Widget _buildActivityImage({double size = 40, double radius = 2}) {
    final src = widget.imageSrc ?? '';
    final isNetwork = src.startsWith('http');

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFDAB7B1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.white70),
    );

    if (src.isEmpty) return placeholder;

    final img = isNetwork
        ? Image.network(
            src,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
          )
        : Image.asset(
            src,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: 45, height: 45, child: img),
    );
  }

  void _showGoalReachedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFEFEAE3),
        title: Text('ถึงเป้าหมายแล้ว',
            style: GoogleFonts.kanit(color: const Color(0xFF564843))),
        content: Text('เยี่ยมมาก! คุณทำครบตามที่ตั้งไว้แล้ว',
            style: GoogleFonts.kanit(color: const Color(0xFF564843))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // ส่งสัญญาณให้หน้า Home refresh
            },
            child: Text('ตกลง',
                style: GoogleFonts.kanit(color: const Color(0xFFC98993))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        (_goalAmount > 0) ? (_goalAmount - _serverCurrent) : double.infinity;
    final sessionAmount = _secondsToUnit(_elapsed.inSeconds);

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
                    onTap: () => Navigator.pop(context, true),
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
            const SizedBox(height: 20),

            // Card
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEAE3),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // รูป + ชื่อกิจกรรม
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'act-${widget.actDetailId}',
                        child: _buildActivityImage(size: 80, radius: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.actName,
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            color: const Color(0xFFC98993),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // วงกลมแสดงเวลา
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: const Color(0xFF564843),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: formatDuration(_elapsed),
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '\n/ ${formatDuration(_target)}',
                                  style: GoogleFonts.kanit(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // ข้อความคืบหน้า
                  if (!_loading)
                    Text(
                      _goalAmount > 0
                          ? 'เวลาที่ทำได้ล่าสุด: ${_formatNum(_serverCurrent)} / ${_formatNum(_goalAmount)} ${widget.unit}'
                          : 'บันทึกแล้ว: ${_formatNum(_serverCurrent)} ${widget.unit}',
                      style: GoogleFonts.kanit(
                        color: const Color(0xFF564843),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ปุ่มเริ่ม/หยุด
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning
                            ? const Color(0xFFE6D2CD)
                            : const Color(0xFFC98993),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(isRunning ? Icons.stop : Icons.play_arrow,
                          color: Colors.white),
                      label: Text(
                        isRunning ? 'หยุดจับเวลา' : 'เริ่มจับเวลา',
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: _loading
                          ? null
                          : () {
                              if (isRunning) {
                                stopTimer();
                              } else {
                                startTimer();
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ปุ่มรีเซ็ต "รอบนี้"
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF564843)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, color: Color(0xFF564843)),
                      label: Text(
                        'รีเซ็ตเวลารอบนี้',
                        style: GoogleFonts.kanit(
                          color: const Color(0xFF564843),
                          fontSize: 16,
                        ),
                      ),
                      onPressed: _loading ? null : _resetSession,
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

  String _formatNum(num n) =>
      (n % 1 == 0) ? n.toInt().toString() : n.toStringAsFixed(2);
}
