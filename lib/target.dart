import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/add_expectations.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';

class Targetpage extends StatefulWidget {
  const Targetpage({super.key});

  @override
  State<Targetpage> createState() => _TargetpageScreenState();
}

class _TargetpageScreenState extends State<Targetpage> {
  int _selectedIndex = 0;

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
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: const Color(0xFF564843),
                height: MediaQuery.of(context).padding.top + 80,
                width: double.infinity,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 70.0),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEAE3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/expectional.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'EXPECTATIONS',
                                    style: GoogleFonts.kanit(
                                      color: const Color(0xFFC98993),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TaskCard(label: 'Dring Water', actId: 1),
                              TaskCard(label: 'Eat', actId: 2),
                              TaskCard(label: 'Maditation', actId: 3),
                              TaskCard(label: 'Walk', actId: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: MediaQuery.of(context).size.width / 2 - 40,
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
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
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
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

class TaskCard extends StatelessWidget {
  final String label;
  final int actId;
  const TaskCard({super.key, required this.label, required this.actId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF564843),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(
          label,
          style: GoogleFonts.kanit(color: Colors.white, fontSize: 18),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE6D2CD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'รายละเอียด',
            style: GoogleFonts.kanit(
              color: const Color(0xFFC98993),
              fontSize: 14,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ExpectationScreen(actId: actId)),
          );
        },
      ),
    );
  }
}
