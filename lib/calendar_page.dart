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

  // ---- Helpers --------------------------------------------------------------

  // ตัดเวลาให้เหลือเฉพาะวัน (local 00:00)
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // แปลงสตริงวันที่จาก API (ฟิลด์ 'date' ของ /dailyPercent) → local 00:00
  // รองรับทั้ง 'YYYY-MM-DD' และ ISO 'YYYY-MM-DDTHH:mm:ssZ'
  DateTime? _parseApiDateToLocalDay(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;

    // ISO
    if (t.contains('T')) {
      try {
        return _dateOnly(DateTime.parse(t).toLocal());
      } catch (_) {}
    }

    // 'YYYY-MM-DD'
    try {
      final base = t.length >= 10 ? t.substring(0, 10) : t;
      final parts = base.split('-');
      if (parts.length == 3) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}

    return null;
  }

  // แปลง create_at ของ activity detail → local 00:00
  DateTime? _parseCreateAtDay(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    try {
      if (s.contains('T')) return _dateOnly(DateTime.parse(s).toLocal());
      if (s.length >= 10) {
        final y = int.parse(s.substring(0, 4));
        final m = int.parse(s.substring(5, 7));
        final d = int.parse(s.substring(8, 10));
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  // ไล่วันแบบรวมปลายทาง
  Iterable<DateTime> _daysInRange(DateTime start, DateTime end) sync* {
    var cur = _dateOnly(start);
    final last = _dateOnly(end);
    while (!cur.isAfter(last)) {
      yield cur;
      cur = cur.add(const Duration(days: 1));
    }
  }

  // ---- Data loader ----------------------------------------------------------

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

      // 🔹 1) เรียก endpoint ใหม่ที่รวม percent รายวันทั้งหมด
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityDetail/dailyPercentAll',
      );

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode != 200) {
        setState(() => _loading = false);
        return;
      }

      // 🔹 2) แปลงข้อมูล JSON ที่ได้
      final jsonBody = jsonDecode(resp.body);
      final List<dynamic> dataList =
          jsonBody is Map && jsonBody['data'] is List ? jsonBody['data'] : [];

      // 🔹 3) ล้างข้อมูลเดิม
      _successDays.clear();
      _failedDays.clear();
      _dailyOverallPercent.clear();

      for (final e in dataList) {
        final dateStr = (e['date'] ?? '').toString();
        final dayKey = _parseApiDateToLocalDay(dateStr);
        if (dayKey == null) continue;

        double pct = 0.0;
        final raw = e['percent'];
        if (raw is num) {
          pct = raw.toDouble();
        } else if (raw is String) {
          pct = double.tryParse(raw) ?? 0.0;
        }

        _dailyOverallPercent[dayKey] = pct;
        if (pct > 50.0) {
          _successDays.add(dayKey);
        } else {
          _failedDays.add(dayKey);
        }
      }
    } catch (e) {
      debugPrint('🔥 Error loading calendar data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- UI -------------------------------------------------------------------

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
                  focusedDay = newFocused; // ตาม docs ไม่จำเป็นต้อง setState
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

                    // ระบายสีเฉพาะวันที่มีข้อมูล
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
    );
  }
}
