import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class Increaseactivity extends StatefulWidget {
  final String actName; // ชื่อกิจกรรมที่กดมา
  final String unit; // หน่วยของกิจกรรม (เช่น แก้ว, ml, km)
  final String actDetailId; // ไว้ใช้ส่งต่อ/บันทึกภายหลัง
  final String? goal; // เป้าหมายรวม (เช่น 3000)
  final String? imageSrc; // รูปกิจกรรม (asset หรือ URL)

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

  // ค่าปัจจุบันและเป้าหมาย
  int _currentAmount = 0; // เริ่มต้นที่ 0 เสมอ -> แสดง 0/goal
  late int _goalAmount; // ตั้งจาก widget.goal หรือดีฟอลต์ 3000

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _goalAmount = int.tryParse(widget.goal ?? '') ?? 3000;
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

  // เพิ่มค่าจากที่ผู้ใช้กรอกเข้ามาแบบบวกเพิ่ม (increment)
  void _addAmount() {
    if (_controller.text.isEmpty) return;

    final value = int.tryParse(_controller.text);
    if (value == null || value <= 0) return;

    if (_currentAmount >= _goalAmount) {
      _controller.clear();
      _showGoalReachedDialog();
      return;
    }

    final newAmount = _currentAmount + value;

    if (newAmount >= _goalAmount) {
      setState(() {
        _currentAmount = _goalAmount; // ล็อกไว้ที่เป้า
        _controller.clear();
      });
      _showGoalReachedDialog();
      return;
    }

    setState(() {
      _currentAmount = newAmount;
      _controller.clear();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
    final unitLabel = widget.unit.isNotEmpty ? widget.unit : '';

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

            // กล่องหลัก
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
                children: [
                  // รูป + ชื่อกิจกรรม (วางข้างกัน)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'act-${widget.actDetailId}',
                        child: _buildActivityImage(size: 60, radius: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.actName,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.kanit(
                            fontSize: 22,
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

                  // วงกลมแสดง "ปัจจุบัน/เป้าหมาย + หน่วย"
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: const Color(0xFF564843),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$_currentAmount',
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
                            text: '$_goalAmount$unitLabel',
                            style: GoogleFonts.kanit(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // กล่องกรอกข้อมูล + ปุ่มเพิ่ม (เช็ค)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6D2CD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.kanit(fontSize: 16),
                            decoration: InputDecoration(
                              hintText:
                                  'Add amount (${unitLabel.isNotEmpty ? unitLabel : 'value'})...',
                              hintStyle:
                                  GoogleFonts.kanit(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _addAmount,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC98993),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
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
