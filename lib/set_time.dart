import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'dart:async';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class CountdownPage extends StatefulWidget {
  final String actName; // << ชื่อกิจกรรมจริง
  final String unit; // << หน่วยที่เลือก (นาที/ชั่วโมง/วินาที หรือ min/hr/sec)
  final String actDetailId; // << ไว้ใช้บันทึก/ส่งต่อภายหลัง
  final String? goal; // << ค่าที่ตั้งไว้ (ถ้ามี)
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
  late Duration _duration; // ตั้งจาก goal+unit
  Timer? _timer;
  bool isRunning = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _duration = _initialDurationFromUnit(widget.unit, widget.goal);
  }

  Duration _initialDurationFromUnit(String? unitRaw, String? goalRaw) {
    final u = (unitRaw ?? '').trim().toLowerCase();
    final val = double.tryParse((goalRaw ?? '').trim());
    // ถ้า goal ว่างหรือไม่ใช่ตัวเลข → ดีฟอลต์ 20 นาที
    if (val == null) return const Duration(minutes: 20);

    // map หน่วยเวลา -> วินาที
    if (u == 'วินาที' ||
        u == 'sec' ||
        u == 'secs' ||
        u == 'second' ||
        u == 'seconds') {
      return Duration(seconds: val.round());
    }
    if (u == 'นาที' ||
        u == 'min' ||
        u == 'mins' ||
        u == 'minute' ||
        u == 'minutes') {
      return Duration(seconds: (val * 60).round());
    }
    if (u == 'ชั่วโมง' ||
        u == 'hr' ||
        u == 'hrs' ||
        u == 'hour' ||
        u == 'hours') {
      return Duration(seconds: (val * 60 * 60).round());
    }
    // ถ้าไม่แมตช์ถือเป็นนาที
    return Duration(seconds: (val * 60).round());
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_duration.inSeconds > 0) {
          _duration -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();
          isRunning = false;
        }
      });
    });
    setState(() => isRunning = true);
  }

  void stopTimer() {
    _timer?.cancel();
    setState(() => isRunning = false);
  }

  void selectNewTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _duration.inHours.clamp(0, 23),
        minute: _duration.inMinutes.remainder(60),
      ),
    );

    if (picked != null) {
      setState(() {
        _duration = Duration(hours: picked.hour, minutes: picked.minute);
        stopTimer();
      });
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

    Widget placeholder = Container(
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
      child: Container(
        width: 45,
        height: 45,
        child: img,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          style: GoogleFonts.kanit(
                              color: Colors.white, fontSize: 16),
                        ),
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
                      offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // รูป + ชื่อกิจกรรม (อยู่ข้างกัน)
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
                            // fontWeight: FontWeight.w600,
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
                    child: Text(
                      formatDuration(_duration),
                      style:
                          GoogleFonts.kanit(color: Colors.white, fontSize: 26),
                      textAlign: TextAlign.center,
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
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(isRunning ? Icons.stop : Icons.play_arrow,
                          color: Colors.white),
                      label: Text(
                        isRunning ? 'หยุดจับเวลา' : 'เริ่มจับเวลา',
                        style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      ),
                      onPressed: () => isRunning ? stopTimer() : startTimer(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ปุ่มเลือกเวลาใหม่ (ชั่วโมง/นาที)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6D2C0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.access_time,
                          color: Color(0xFF564843)),
                      label: Text(
                        'ตั้งเวลาใหม่',
                        style: GoogleFonts.kanit(
                            color: const Color(0xFF564843),
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      ),
                      onPressed: selectNewTime,
                    ),
                  ),
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
