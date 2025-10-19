// lib/screens/increase_activity.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// REST & Auth
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pj1/constant/api_endpoint.dart';

class Increaseactivity extends StatefulWidget {
  final String actName; // ชื่อกิจกรรม
  final String unit; // หน่วย (ml, km, hr, ครั้ง ฯลฯ)
  final String
      actDetailId; // id ของ activity_detail (รับเป็น String แต่จะแปลงเป็น int ตอนยิง)
  final String? goal; // เป้าหมายรวม (string)
  final String? imageSrc; // asset หรือ URL

  const Increaseactivity({
    super.key,
    required this.actName,
    required this.unit,
    required this.actDetailId,
    this.goal,
    this.imageSrc,
  });

  @override
  _IncreaseactivityPageState createState() => _IncreaseactivityPageState();
}

class _IncreaseactivityPageState extends State<Increaseactivity> {
  double _currentAmount = 0.0;
  late double _goalAmount;

  final TextEditingController _controller = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = false;
  bool _hasChanged = false;

  double? _latestValue;

  // ========= Utilities =========
  Future<Map<String, String>> _authHeaders() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  String _fmt(num n) => (n % 1 == 0) ? n.toInt().toString() : n.toString();

  bool get _isCompleted => _goalAmount > 0 && _currentAmount >= _goalAmount;

  // 🔒 ตัดค่าไม่ให้เกินเป้า (เรียกใช้ทุกครั้งหลังได้ค่าจาก server หรือจะ setState)
  void _enforceGoalCap() {
    if (_goalAmount > 0 && _currentAmount > _goalAmount) {
      _currentAmount = _goalAmount;
    }
  }

  @override
  void initState() {
    super.initState();
    _goalAmount = double.tryParse(widget.goal ?? '') ?? 3000.0;
    _fetchCurrentValue(widget.actDetailId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ========= API Calls =========

  // ดึงยอดรวม "วันนี้" ของกิจกรรมนี้
  Future<void> _fetchCurrentValue(String actDetailId) async {
    setState(() => _isLoading = true);

    try {
      final int? actDetailIdInt = int.tryParse(actDetailId);
      if (actDetailIdInt == null) {
        debugPrint('act_detail_id is not a number: $actDetailId');
        return;
      }

      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/getTodaySum',
      ).replace(queryParameters: {'act_detail_id': '$actDetailIdInt'});

      final res = await http.get(url, headers: await _authHeaders());

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final ts = data['todaySum'];
        if (ts is num) {
          _currentAmount = ts.toDouble();
        } else if (ts is String && ts.isNotEmpty) {
          _currentAmount = double.tryParse(ts) ?? _currentAmount;
        } else {
          _currentAmount = 0;
        }

        final g = data['goal'];
        if (g is num) {
          _goalAmount = g.toDouble();
        } else if (g is String && g.isNotEmpty) {
          _goalAmount = double.tryParse(g) ?? _goalAmount;
        }

        _enforceGoalCap(); // 🔒 กันหลุดเกินเป้า

        if (mounted) setState(() {});
      } else {
        debugPrint('fetch current_value failed: ${res.statusCode} ${res.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ (${res.statusCode})')),
          );
        }
      }
    } catch (e) {
      debugPrint('fetch current_value error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // เพิ่มจำนวนแบบ "บวกเพิ่ม" (เพิ่มเฉพาะที่ไม่เกินเป้า)
  Future<bool> _persistIncrease(double amountToAdd) async {
    if (_isSaving) return false;
    setState(() => _isSaving = true);

    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/increaseCurrentValue',
      );

      final headers = await _authHeaders();

      final int? actDetailIdInt = int.tryParse(widget.actDetailId);
      if (actDetailIdInt == null) {
        debugPrint('act_detail_id is not a number: ${widget.actDetailId}');
        throw Exception('act_detail_id invalid');
      }

      // กัน NaN/negative
      double action = amountToAdd.isFinite ? amountToAdd : 0;
      if (action < 0) action = 0;

      // กัน overshoot (บวกได้ไม่เกินที่เหลือ)
      if (_goalAmount > 0) {
        final remain = (_goalAmount - _currentAmount).clamp(0, double.infinity);
        if (action > remain) action = remain.toDouble();
      }

      final body = jsonEncode({
        'act_detail_id': actDetailIdInt,
        'action': action,
      });

      final res = await http.post(url, headers: headers, body: body);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // รองรับทั้ง current_value และ todaySum
        final cv = data['current_value'] ?? data['todaySum'];
        if (cv is num) {
          _currentAmount = cv.toDouble();
        } else if (cv is String) {
          _currentAmount = double.tryParse(cv) ?? _currentAmount;
        }

        final g = data['goal'];
        if (g != null) {
          if (g is num) {
            _goalAmount = g.toDouble();
          } else if (g is String) {
            _goalAmount = double.tryParse(g) ?? _goalAmount;
          }
        }

        _enforceGoalCap(); // 🔒 กันหลุด

        _hasChanged = true;
        if (mounted) setState(() {});
        return true;
      } else {
        debugPrint('Increase failed: ${res.statusCode} ${res.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เพิ่มค่าไม่สำเร็จ (${res.statusCode})')),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Increase error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ดึงค่าล่าสุดของ "วันนี้" (ไว้โชว์ใน dialog แก้ไข)
  Future<void> _fetchLatestValue() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;

      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/latest',
      ).replace(queryParameters: {'act_detail_id': widget.actDetailId});

      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          final latestAction = data['latestAction'];
          if (latestAction is num) {
            _latestValue = latestAction.toDouble();
          } else if (latestAction is String) {
            _latestValue = double.tryParse(latestAction);
          } else {
            _latestValue = 0;
          }
        });
      } else {
        debugPrint('โหลดค่าล่าสุดไม่สำเร็จ: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการดึงค่าล่าสุด: $e');
    }
  }

  // ตั้งค่ารวมของวันนี้เป็นค่าใหม่แบบ "absolute"
  Future<void> _persistUpdateAbsolute(double newValue) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/updateCurrentValue',
      );

      final headers = await _authHeaders();

      final int? actDetailIdInt = int.tryParse(widget.actDetailId);
      if (actDetailIdInt == null) {
        debugPrint('act_detail_id is not a number: ${widget.actDetailId}');
        throw Exception('act_detail_id invalid');
      }

      // กันค่าติดลบ/NaN และไม่ให้เกิน goal
      double safeValue = newValue.isFinite ? (newValue < 0 ? 0 : newValue) : 0;
      if (_goalAmount > 0 && safeValue > _goalAmount) {
        safeValue = _goalAmount;
      }

      final body = jsonEncode({
        'act_detail_id': actDetailIdInt,
        'action': safeValue,
      });

      final res = await http.put(url, headers: headers, body: body);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final tv = data['todaySum'] ?? data['current_value'];
        if (tv is num) {
          _currentAmount = tv.toDouble();
        } else if (tv is String) {
          _currentAmount = double.tryParse(tv) ?? _currentAmount;
        }

        final g = data['goal'];
        if (g is num) {
          _goalAmount = g.toDouble();
        } else if (g is String) {
          _goalAmount = double.tryParse(g) ?? _goalAmount;
        }

        _enforceGoalCap(); // 🔒 กันหลุด

        _hasChanged = true;
        if (mounted) setState(() {}); // อัปเดตทันที

        // รีเฟรชจาก server เพื่อความชัวร์
        await _fetchCurrentValue(widget.actDetailId);
      } else {
        debugPrint('Update absolute failed: ${res.statusCode} ${res.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกไม่สำเร็จ (${res.statusCode})')),
          );
        }
      }
    } catch (e) {
      debugPrint('Update absolute error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ========= UI Actions =========

  Future<void> _addAmount() async {
    if (_isSaving) return;

    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    final value = double.tryParse(raw.replaceAll(',', ''));
    if (value == null || value <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนที่มากกว่า 0')),
      );
      return;
    }

    double toAdd = value;

    // กัน overshoot ฝั่ง UI อีกชั้น
    if (_goalAmount > 0) {
      final double remain = (_goalAmount - _currentAmount);
      if (remain <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ทำครบเป้าหมายแล้ว')),
        );
        return;
      }
      if (toAdd > remain) toAdd = remain;
      if (toAdd < 0) toAdd = 0;
    }

    FocusScope.of(context).unfocus();

    final ok = await _persistIncrease(toAdd);
    if (ok) {
      await _fetchCurrentValue(widget.actDetailId); // รีเฟรชหลังเพิ่มสำเร็จ
    }
    _controller.clear();

    if (_currentAmount >= _goalAmount && _goalAmount > 0) {
      _showGoalReachedDialog();
    }
  }

  void _showGoalReachedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFEFEAE3),
        title: Text(
          'คุณทำตามเป้าหมายแล้ว',
          style: GoogleFonts.kanit(color: const Color(0xFF564843)),
        ),
        content: Text(
          'เยี่ยมมาก! วันนี้คุณถึงเป้าหมายที่ตั้งไว้เรียบร้อย 🎯',
          style: GoogleFonts.kanit(color: const Color(0xFF564843)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง',
                style: GoogleFonts.kanit(color: const Color(0xFFC98993))),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog() async {
    final TextEditingController editCtl =
        TextEditingController(text: _fmt(_currentAmount));

    await _fetchLatestValue(); // โหลดค่าล่าสุดก่อนเปิด Dialog

    await showDialog(
      context: context,
      builder: (ctx) {
        // เติมค่าล่าสุดลงไปเป็นค่าเริ่มต้น
        editCtl.text = _fmt(_latestValue ?? _currentAmount);

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFEFEAE3),
          title: Text('แก้ไขค่าล่าสุด',
              style: GoogleFonts.kanit(color: const Color(0xFF564843))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_goalAmount > 0)
                Text(
                  'เป้าหมาย: ${_fmt(_goalAmount)} ${widget.unit}',
                  style: GoogleFonts.kanit(color: const Color(0xFF564843)),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: editCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
                style: GoogleFonts.kanit(),
                decoration: InputDecoration(
                  hintText: 'ค่าปัจจุบันใหม่ (${widget.unit})',
                  hintStyle: GoogleFonts.kanit(color: Colors.black45),
                  filled: true,
                  fillColor: const Color(0xFFE6D2CD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ค่าปัจจุบัน: ${_fmt(_currentAmount)} ${widget.unit}',
                style: GoogleFonts.kanit(color: const Color(0xFF564843)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ยกเลิก',
                  style: GoogleFonts.kanit(color: const Color(0xFFC98993))),
            ),
            TextButton(
              onPressed: () async {
                final raw = editCtl.text.trim();
                final newVal = double.tryParse(raw.replaceAll(',', ''));
                if (newVal == null || newVal < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('กรุณากรอกตัวเลขที่ถูกต้อง (≥ 0)')),
                  );
                  return;
                }
                if (_goalAmount > 0 && newVal > _goalAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ห้ามเกินเป้าหมาย ${_fmt(_goalAmount)} ${widget.unit}',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  _currentAmount = newVal; // อัปเดตทันทีในหน้า
                  _enforceGoalCap(); // 🔒 กันหลุด ณ จุดนี้ด้วย
                  _hasChanged = true;
                });

                Navigator.pop(ctx); // ปิด Dialog

                // ยิงอัปเดต absolute และรีเฟรชจาก server ภายในฟังก์ชัน
                await _persistUpdateAbsolute(_currentAmount);

                if (_goalAmount > 0 && _currentAmount >= _goalAmount) {
                  _showGoalReachedDialog();
                }
              },
              child: Text('บันทึก',
                  style: GoogleFonts.kanit(color: const Color(0xFF564843))),
            ),
          ],
        );
      },
    );
  }

  // ========= UI =========

  Widget _buildActivityImage({double size = 40, double radius = 12}) {
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
      child: SizedBox(width: size, height: size, child: img),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.unit.isNotEmpty ? widget.unit : '';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFC98993),
        body: RefreshIndicator(
          onRefresh: () => _fetchCurrentValue(widget.actDetailId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                        onTap: () => Navigator.pop(context, _hasChanged),
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'act-${widget.actDetailId}',
                            child: _buildActivityImage(size: 50, radius: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.actName,
                              textAlign: TextAlign.start,
                              style: GoogleFonts.kanit(
                                fontSize: 22,
                                color: const Color(0xFFC98993),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // วงกลมค่าปัจจุบัน/เป้าหมาย
                      CircleAvatar(
                        radius: 75,
                        backgroundColor: const Color(0xFF564843),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _fmt(_currentAmount),
                                      style: GoogleFonts.kanit(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/',
                                      style: GoogleFonts.kanit(
                                        color: Colors.white,
                                        fontSize: 22,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '${_fmt(_goalAmount)}${unitLabel.isNotEmpty ? ' $unitLabel' : ''}',
                                      style: GoogleFonts.kanit(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_isCompleted)
                                      TextSpan(
                                        text: '\nเสร็จแล้ว 🎉',
                                        style: GoogleFonts.kanit(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: 28),

                      // กล่องกรอก + ปุ่มบวก
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6D2CD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  signed: false,
                                  decimal: true,
                                ),
                                style: GoogleFonts.kanit(fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: _isCompleted
                                      ? 'ทำครบเป้าหมายแล้ว'
                                      : 'Add amount (${unitLabel.isNotEmpty ? unitLabel : 'value'})...',
                                  hintStyle:
                                      GoogleFonts.kanit(color: Colors.white70),
                                  border: InputBorder.none,
                                ),
                                enabled: !_isSaving && !_isCompleted,
                              ),
                            ),
                            GestureDetector(
                              onTap: (_isSaving || _isCompleted)
                                  ? null
                                  : _addAmount,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (_isSaving || _isCompleted)
                                      ? const Color(0xFFC98993).withOpacity(0.6)
                                      : const Color(0xFFC98993),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check,
                                        color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ปุ่มแก้ไขค่าล่าสุดแบบ absolute
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE6D2C0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon:
                              const Icon(Icons.edit, color: Color(0xFFC98993)),
                          label: Text(
                            'แก้ไขค่าล่าสุด',
                            style: GoogleFonts.kanit(
                              color: const Color(0xFFC98993),
                              fontSize: 16,
                            ),
                          ),
                          onPressed: _isLoading ? null : _openEditDialog,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
