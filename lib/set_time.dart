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

class CountdownPage extends StatefulWidget {
  final String actName; // ชื่อกิจกรรมจริง
  final String unit; // หน่วยที่เลือก (วินาที/นาที/ชั่วโมง หรือ sec/min/hr)
  final String actDetailId; // ใช้บันทึก/ส่งต่อภายหลัง
  final String? goal; // ค่าที่ตั้งไว้ (ถ้ามี)
  final String? imageSrc; // รูปกิจกรรม (asset หรือ URL)

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
  // นับแบบเดินหน้า
  Duration _elapsed = Duration.zero; // เวลาที่วิ่งใน "รอบนี้"
  late Duration _target; // ระยะเวลาเป้าหมาย
  Timer? _timer;
  bool isRunning = false;
  int _selectedIndex = 0;

  // ค่าในฐานข้อมูล
  double _serverCurrent = 0.0; // current_value (ตามหน่วยที่ผู้ใช้ตั้ง)
  double _goalAmount = 0.0; // goal (ตามหน่วยเดียวกัน)
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // ตั้ง target เริ่มต้นจากพารามิเตอร์ (ถ้าฐานข้อมูลมีค่าจริง จะ override ใน _fetchDetail)
    _goalAmount =
        double.tryParse(widget.goal ?? '') ?? 20.0; // ดีฟอลต์ 20 "นาที"
    _target = _durationFromUnit(widget.unit, _goalAmount);
    _fetchDetail(); // ดึงค่า goal/current ล่าสุดจากหลังบ้าน
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- REST ----------
  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityDetail/activity-detail/${Uri.encodeComponent(widget.actDetailId)}',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // goal
        final g = data['goal'];
        if (g is num) _goalAmount = g.toDouble();
        if (g is String) _goalAmount = double.tryParse(g) ?? _goalAmount;

        // current_value
        final cv = data['current_value'];
        if (cv is num) _serverCurrent = cv.toDouble();
        if (cv is String)
          _serverCurrent = double.tryParse(cv) ?? _serverCurrent;

        // อัปเดต target duration จาก goal (ตามหน่วย)
        _target = _durationFromUnit(widget.unit, _goalAmount);
      } else {
        debugPrint('fetch detail failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('fetch detail error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetSession() {
    // รีเซ็ตเวลาที่จับใน "รอบนี้" เฉพาะในแอป ไม่แตะค่าที่บันทึกในฐานข้อมูล
    setState(() {
      _elapsed = Duration.zero;
    });

    // ถ้ากดตอนกำลังวิ่งอยู่ Timer จะเดินต่อจาก 00:00 ทันที
    // ถ้าอยากให้รีเซ็ตแล้ว "หยุด" ด้วย ให้ยกเลิกคอมเมนต์ 2 บรรทัดล่างนี้
    // _timer?.cancel();
    // isRunning = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('รีเซ็ตเวลารอบนี้แล้ว')),
    );
  }

  Future<void> _persistIncrease(double amountToAdd) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityDetail/activity-detail/${Uri.encodeComponent(widget.actDetailId)}/increase',
      );
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'amount': amountToAdd}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cv = data['current_value'];
        if (cv is num) _serverCurrent = cv.toDouble();
        if (cv is String)
          _serverCurrent = double.tryParse(cv) ?? _serverCurrent;

        final g = data['goal'];
        if (g != null) {
          if (g is num) _goalAmount = g.toDouble();
          if (g is String) _goalAmount = double.tryParse(g) ?? _goalAmount;
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

  // แปลง goal (ตามหน่วย) → Duration เป้าหมาย
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
    // ถ้าไม่แมตช์ ให้ตีเป็น "นาที"
    return Duration(seconds: (goalVal * 60).round());
  }

  // แปลง "วินาที" → จำนวนตามหน่วยของกิจกรรม (sec/min/hr)
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
    // ดีฟอลต์เป็นนาที
    return seconds / 60.0;
  }

  void startTimer() {
    _timer?.cancel();
    isRunning = true;
    setState(() {});

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      // ถ้าใน DB ครบเป้าแล้ว ไม่ต้องวิ่งต่อ
      if (_goalAmount > 0 && _serverCurrent >= _goalAmount) {
        _timer?.cancel();
        isRunning = false;
        setState(() {});
        _showGoalReachedDialog();
        return;
      }

      setState(() {
        // เดินหน้า +1 วินาที
        _elapsed += const Duration(seconds: 1);
      });

      // คำนวณส่วนที่วิ่งในรอบนี้เป็นหน่วยจริง
      final sessionAmount = _secondsToUnit(_elapsed.inSeconds);
      final remaining =
          (_goalAmount > 0) ? (_goalAmount - _serverCurrent) : double.infinity;

      // ถ้าถึงเป้าหมาย (session เกินส่วนที่เหลือ) → หยุด + บันทึกที่เหลือให้ครบเป้า
      if (sessionAmount >= remaining && remaining.isFinite) {
        _timer?.cancel();
        isRunning = false;
        setState(() {});
        _handleSaveAndGoal(remaining);
      }
    });
  }

  // หยุด และบันทึกเวลาที่วิ่งในรอบนี้ (แต่อย่าเกินส่วนที่เหลือ)
  void stopTimer() {
    _timer?.cancel();
    isRunning = false;

    final sessionAmount = _secondsToUnit(_elapsed.inSeconds);
    final remaining =
        (_goalAmount > 0) ? (_goalAmount - _serverCurrent) : double.infinity;
    final toAdd = remaining.isFinite
        ? (sessionAmount.clamp(0.0, remaining)).toDouble()
        : sessionAmount;

    // reset elapsed ก่อน (กันกดรัว/กดซ้ำ)
    setState(() {});
    _saveSessionAndReset(toAdd);
  }

  // บันทึกเมื่อตอนครบเป้า
  void _handleSaveAndGoal(double remaining) async {
    await _persistIncrease(remaining);
    _elapsed = Duration.zero;
    if (!mounted) return;
    setState(() {});
    _showGoalReachedDialog();
  }

  // บันทึกเวลาที่วิ่งในรอบนี้ และ reset elapsed
  void _saveSessionAndReset(double toAdd) async {
    if (toAdd > 0) {
      await _persistIncrease(toAdd);
    }
    _elapsed = Duration.zero;
    if (mounted) setState(() {});
  }

  void selectNewTime() async {
    // ให้ผู้ใช้ปรับ target (ชั่วโมง/นาที) ใหม่ได้ — ไม่ยุ่ง DB
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
        _elapsed = Duration.zero; // รีเซ็ตรอบนี้
        isRunning = false;
      });
      _timer?.cancel();
    }
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

  // วิดเจ็ตแสดงรูปกิจกรรม (รองรับ asset/URL + fallback)
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
              Navigator.pop(context); // ปิด dialog
              Navigator.pop(
                  context, true); // ย้อนกลับไปหน้า Home พร้อมสัญญาณให้ refresh
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
    final sessionAmount =
        _secondsToUnit(_elapsed.inSeconds); // ที่วิ่งในรอบนี้ (หน่วยจริง)

    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนหัว Stack
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
                    onTap: () => Navigator.pop(
                        context, true), // <- บอกหน้า Home ให้รีเฟรช
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

            // การ์ดหลัก
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

                  // วงกลมแสดงเวลา: แสดง "elapsed / target" (นับเดินหน้า)
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

                  // แถบข้อความคืบหน้า (อิงค่าที่บันทึกใน DB + รอบนี้)
                  if (!_loading)
                    Text(
                      _goalAmount > 0
                          ? 'เวลาที่ทำได้ล่าสุด: ${_formatNum(_serverCurrent)} / ${_formatNum(_goalAmount)} ${widget.unit}'
                          : 'บันทึกแล้ว: ${_formatNum(_serverCurrent)} ${widget.unit}',
                      style: GoogleFonts.kanit(
                          color: const Color(0xFF564843),
                          fontSize: 16,
                          fontWeight: FontWeight.w300),
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

                  // ปุ่มรีเซ็ต "รอบนี้" (ไม่แตะค่าที่บันทึกใน DB)
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
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                ],
              ),
            )
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

  String _formatNum(num n) {
    return (n % 1 == 0) ? n.toInt().toString() : n.toStringAsFixed(2);
  }
}
