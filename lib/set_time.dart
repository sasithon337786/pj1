import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'dart:async';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class CountdownPage extends StatefulWidget {
  @override
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  Duration _duration = Duration(minutes: 20);
  Timer? _timer;
  bool isRunning = false;
  int _selectedIndex = 0;

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        if (_duration.inSeconds > 0) {
          _duration -= Duration(seconds: 1);
        } else {
          _timer?.cancel();
          isRunning = false;
        }
      });
    });
    setState(() {
      isRunning = true;
    });
  }

  void stopTimer() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void selectNewTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _duration.inHours,
        minute: _duration.inMinutes % 60,
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
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes : $seconds min";
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Targetpage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Graphpage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountPage()),
        );
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
                    SizedBox(height: 60),
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
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ย้อนกลับ',
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(24),
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Color(0xFFEFEAE3),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Yoka',
                    style: GoogleFonts.kanit(
                      fontSize: 28,
                      color: Color(0xFFC98993),
                    ),
                  ),
                  SizedBox(height: 24),
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: Color(0xFF564843),
                    child: Text(
                      formatDuration(_duration),
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isRunning ? Color(0xFFE6D2CD) : Color(0xFFC98993),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        isRunning ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      label: Text(
                        isRunning ? 'หยุดจับเวลา' : 'เริ่มจับเวลา',
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        isRunning ? stopTimer() : startTimer();
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE6D2C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.access_time, color: Color(0xFF564843)),
                      label: Text(
                        'เลื่อนเวลา',
                        style: GoogleFonts.kanit(
                          color: Color(0xFF564843),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
