import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  // เก็บผลรวมแต่ละวัน (ใช้ DateTime local 00:00 เป็นคีย์เสมอ)
  final Set<DateTime> _successDays = {};
  final Set<DateTime> _failedDays = {};
  final Map<DateTime, double> _dailyOverallPercent = {};

  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  // สร้างคีย์วันแบบ local 00:00 (ไม่ติด timezone/เวลา)
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // แปลงสตริงวันที่จาก API เป็น "วันที่ตามเครื่อง" แล้วตัดเวลาเหลือ 00:00
  // รองรับทั้ง 'YYYY-MM-DD' และ ISO 'YYYY-MM-DDTHH:mm:ssZ'
  DateTime? _parseApiDateToLocalDay(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;

    if (t.contains('T')) {
      // ISO → parse → toLocal() → ตัดเป็นคีย์วัน local
      try {
        final dt = DateTime.parse(t).toLocal();
        return _dateOnly(dt);
      } catch (_) {
        // ตกไปเคสธรรมดาด้านล่าง
      }
    }

    // 'YYYY-MM-DD'
    final base = t.length >= 10 ? t.substring(0, 10) : t;
    final parts = base.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }

  Future<void> _loadCalendarData() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
      final idToken = await user.getIdToken(true);
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $idToken',
      };

      // 1) ดึงกิจกรรมทั้งหมดของผู้ใช้
      final actsUrl = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityDetail/getMyActivityDetails?uid=${user.uid}',
      );
      final actsResp = await http.get(actsUrl, headers: headers);
      if (actsResp.statusCode != 200) {
        setState(() => _loading = false);
        return;
      }
      final List acts = jsonDecode(actsResp.body) as List;

      // รวม act_detail_id
      final List<int> actDetailIds = [];
      for (var a in acts) {
        final v = a['act_detail_id'];
        if (v == null) continue;
        if (v is int) {
          actDetailIds.add(v);
        } else if (v is num) {
          actDetailIds.add(v.toInt());
        } else if (v is String) {
          final p = int.tryParse(v);
          if (p != null) actDetailIds.add(p);
        }
      }
      if (actDetailIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // 2) ดึง dailyPercent ของทุก activity (ขนาน)
      final futures = actDetailIds.map((id) async {
        final url = Uri.parse(
            '${ApiEndpoints.baseUrl}/api/activityHistory/dailyPercent?act_detail_id=$id');
        try {
          final resp = await http.get(url, headers: headers);
          if (resp.statusCode == 200) {
            final body = jsonDecode(resp.body);
            if (body is List) return body;
          }
        } catch (_) {}
        return [];
      }).toList();

      final results = await Future.wait(futures);

      // 3) รวมเป็นเปอร์เซ็นต์เฉลี่ยต่อวัน (key คือวัน local 00:00)
      final Map<DateTime, List<double>> perDayPercents = {};
      for (final list in results) {
        for (final e in list) {
          final dateStr = (e['date'] ?? '').toString();
          if (dateStr.isEmpty) continue;

          // ✅ แปลงเป็นวัน local (แก้ปัญหา ...Z ช้า 1 วัน)
          final dayKey = _parseApiDateToLocalDay(dateStr);
          if (dayKey == null) continue;

          double pct = 0.0;
          final raw = e['percent'];
          if (raw is num) {
            pct = raw.toDouble();
          } else if (raw is String) {
            pct = double.tryParse(raw) ?? 0.0;
          } else {
            continue;
          }

          perDayPercents
              .putIfAbsent(dayKey, () => [])
              .add(pct.clamp(0.0, 100.0));
        }
      }

      _successDays.clear();
      _failedDays.clear();
      _dailyOverallPercent.clear();

      perDayPercents.forEach((day, list) {
        if (list.isEmpty) return;
        final avg = list.reduce((a, b) => a + b) / list.length;
        _dailyOverallPercent[day] = avg;
        if (avg > 50.0) {
          _successDays.add(day);
        } else {
          _failedDays.add(day);
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Targetpage()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Graphpage()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AccountPage()));
        break;
    }
  }

  Widget _legendDot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    // เปอร์เซ็นต์ของวันที่เลือก (ถ้าไม่เลือก ใช้วันโฟกัส)
    final DateTime keyDay = _dateOnly(selectedDay ?? focusedDay);
    final double? dayPercent = _dailyOverallPercent[keyDay];

    return Scaffold(
      backgroundColor: const Color(0xFFC98993),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------- Header ----------
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
                        Text('ย้อนกลับ',
                            style: GoogleFonts.kanit(
                                color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------- Title chip ----------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECE6E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF3B6C8A)),
                  const SizedBox(width: 8),
                  Text(
                    "Calendar",
                    style: GoogleFonts.kanit(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ---------- Legend ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.green.shade400),
                Text('  > 50%  ',
                    style: GoogleFonts.kanit(color: Colors.white)),
                _legendDot(Colors.red.shade400),
                Text('  ≤ 50%  ',
                    style: GoogleFonts.kanit(color: Colors.white)),
                if (_loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  Text(' กำลังโหลด...',
                      style: GoogleFonts.kanit(color: Colors.white)),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // ---------- Calendar ----------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                },
                onPageChanged: (newFocused) {
                  focusedDay = newFocused; // ไม่จำเป็นต้อง setState ตาม docs
                },
                calendarStyle: CalendarStyle(
                  defaultTextStyle: GoogleFonts.kanit(color: Colors.black87),
                  weekendTextStyle: GoogleFonts.kanit(color: Colors.black87),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFFC98993),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleTextFormatter: (date, locale) =>
                      DateFormat('MMM yyyy').format(date),
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle:
                      GoogleFonts.kanit(fontSize: 18, color: Colors.black87),
                  leftChevronIcon: const Icon(Icons.chevron_left),
                  rightChevronIcon: const Icon(Icons.chevron_right),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final d = _dateOnly(day);
                    final pct = _dailyOverallPercent[d];

                    // ระบายสีเฉพาะวันที่มีข้อมูล (ตามเงื่อนไข >50% / ≤50%)
                    Color? fill;
                    if (pct != null) {
                      fill = (pct > 50.0)
                          ? Colors.green.shade400
                          : Colors.red.shade400;
                    }

                    if (fill == null) return null;

                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration:
                          BoxDecoration(color: fill, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: GoogleFonts.kanit(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ---------- Encouragement box ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  (dayPercent != null)
                      ? 'คุณทำได้ ${dayPercent.toStringAsFixed(1)}% จากเป้าหมาย 🎯\n'
                          'เก่งมากๆ แล้วนะคะ! ในวันต่อๆ ไปก็สู้ๆ นะคะ \n'
                          'Do your best!💪🌟🙌❤️'
                      : 'ยังไม่มีข้อมูลเปอร์เซ็นต์\n'
                          'เก่งมากๆ แล้วนะคะ! ในวันต่อๆ ไปก็สู้ๆ นะคะ \n'
                          'Do your best!💪🌟🙌❤️',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    color: const Color(0xFF5A3E42),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),
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
}
