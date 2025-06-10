import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pj1/account.dart';
import 'package:pj1/grap.dart';
import 'package:pj1/mains.dart';
import 'package:pj1/target.dart';

class MainAddmin extends StatefulWidget {
  const MainAddmin({Key? key}) : super(key: key);

  @override
  State<MainAddmin> createState() => _MainAddminState();
}

class _MainAddminState extends State<MainAddmin> {
  final List<String> users = ['Nutty', 'แฟรงค์', 'Mozel', 'คิวคิวคิว'];

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
      body: Column(
        children: [
          // Header UI
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
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF564843),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/icons/admin.png',
                          width: 20, height: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Addmin',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content User List
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/man.png',
                            width: 35,
                            height: 35,
                          ),
                          const SizedBox(
                              width: 8), // เพิ่มช่องว่างระหว่าง icon กับ text
                          Text(
                            'User',
                            style: GoogleFonts.kanit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF564843),
                            ),
                          ),
                        ],
                      ),

                      // รายการ Users
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF564843),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  users[index],
                                  style: GoogleFonts.kanit(
                                    fontSize: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: รายละเอียด
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE6D2CD),
                                    foregroundColor: const Color(0xFF564843),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'รายละเอียด',
                                    style: GoogleFonts.kanit(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
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
