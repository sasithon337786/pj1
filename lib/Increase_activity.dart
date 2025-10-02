import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

// ====== REST ======
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // ✅ ใช้ดึง idToken
import 'package:pj1/constant/api_endpoint.dart';
// ===================

class Increaseactivity extends StatefulWidget {
  final String actName; // ชื่อกิจกรรม
  final String unit; // หน่วย (ml, km, hr, ครั้ง ฯลฯ)
  final String actDetailId; // id ของ activity_detail
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
  int _selectedIndex = 0;

  double _currentAmount = 0.0;
  late double _goalAmount;

  final TextEditingController _controller = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = false;

  bool _hasChanged = false;

  // ✅ headers พร้อม Bearer token
  Future<Map<String, String>> _authHeaders() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }

  String _fmt(num n) {
    if (n % 1 == 0) return n.toInt().toString();
    return n.toString();
  }

  bool get _isCompleted => _goalAmount > 0 && _currentAmount >= _goalAmount;

  @override
  void initState() {
    super.initState();
    _goalAmount = double.tryParse(widget.goal ?? '') ?? 3000.0;
    // เรียกดึงค่า current/goal ตอนหน้าเริ่มต้น
    _fetchCurrentValue(widget.actDetailId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ดึง current_value ล่าสุด (ต้องแนบ token)
  Future<void> _fetchCurrentValue(String actDetailId) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken(true);
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/getTodaySum?uid=${user.uid}&act_detail_id=$actDetailId',
      );

      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // ดึง total action ของวันนี้
        final todaySum = data['todaySum'];
        if (todaySum is num)
          _currentAmount = todaySum.toDouble();
        else if (todaySum is String)
          _currentAmount = double.tryParse(todaySum) ?? _currentAmount;

        // ดึง goal จาก response
        final g = data['goal'];
        if (g != null) {
          if (g is num)
            _goalAmount = g.toDouble();
          else if (g is String) _goalAmount = double.tryParse(g) ?? _goalAmount;
        }

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

  void _showGoalReachedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFEFEAE3),
        title: Text('ถึงเป้าหมายแล้ว',
            style: GoogleFonts.kanit(color: const Color(0xFF564843))),
        content: Text('คุณใส่ข้อมูลครบตามที่ตั้งเป้าไว้แล้ว',
            style: GoogleFonts.kanit(color: const Color(0xFF564843))),
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

  Future<void> _persistIncrease(double amountToAdd) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/increaseCurrentValue?act_detail_id=${Uri.encodeComponent(widget.actDetailId)}',
      );

      final res = await http.post(
        url,
        headers: await _authHeaders(),
        body: jsonEncode({'action': amountToAdd}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cv = data['current_value'];
        if (cv is num)
          _currentAmount = cv.toDouble();
        else if (cv is String)
          _currentAmount = double.tryParse(cv) ?? _currentAmount;

        final g = data['goal'];
        if (g != null) {
          if (g is num)
            _goalAmount = g.toDouble();
          else if (g is String) _goalAmount = double.tryParse(g) ?? _goalAmount;
        }

        _hasChanged = true;
        if (mounted) setState(() {});
      } else {
        debugPrint('Increase failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Increase error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _persistUpdateAbsolute(double newValue) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/activityHistory/updateCurrentValue?act_detail_id=${Uri.encodeComponent(widget.actDetailId)}',
      );
      final res = await http.put(url,
          headers: await _authHeaders(),
          body: jsonEncode({'current_value': newValue}));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cv = data['current_value'];
        if (cv is num)
          _currentAmount = cv.toDouble();
        else if (cv is String)
          _currentAmount = double.tryParse(cv) ?? _currentAmount;

        final g = data['goal'];
        if (g != null) {
          if (g is num)
            _goalAmount = g.toDouble();
          else if (g is String) _goalAmount = double.tryParse(g) ?? _goalAmount;
        }

        _hasChanged = true;
        if (mounted) setState(() {});
      } else {
        debugPrint('Update absolute failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Update absolute error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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

    await _persistIncrease(toAdd);
    await _fetchCurrentValue(widget.actDetailId);
    _controller.clear();

    if (_currentAmount >= _goalAmount && _goalAmount > 0) {
      _showGoalReachedDialog();
    }
  }

  Future<void> _openEditDialog() async {
    final TextEditingController editCtl =
        TextEditingController(text: _fmt(_currentAmount));

    await showDialog(
      context: context,
      builder: (ctx) {
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
                          'ห้ามเกินเป้าหมาย ${_fmt(_goalAmount)} ${widget.unit}'),
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                await _persistUpdateAbsolute(newVal);

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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
        body: SingleChildScrollView(
          child: Column(
            children: [
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
                    CircleAvatar(
                      radius: 75,
                      backgroundColor: const Color(0xFF564843),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
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
                            onTap:
                                (_isSaving || _isCompleted) ? null : _addAmount,
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
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check,
                                      color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        icon: const Icon(Icons.edit, color: Color(0xFFC98993)),
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
              icon:
                  Image.asset('assets/icons/stats.png', width: 24, height: 24),
              label: 'Graph',
            ),
            BottomNavigationBarItem(
              icon:
                  Image.asset('assets/icons/accout.png', width: 24, height: 24),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
