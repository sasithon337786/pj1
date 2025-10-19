import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:pj1/Addmin/deteiluser_suspended.dart';
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/constant/api_endpoint.dart';
import 'package:pj1/models/ListuserPetition.dart';

class ListuserPetition extends StatefulWidget {
  const ListuserPetition({Key? key}) : super(key: key);

  @override
  State<ListuserPetition> createState() => _ListuserPetitionState();
}

class _ListuserPetitionState extends State<ListuserPetition> {
  int _selectedIndex = 3;

  List<PetitionItem> petitions = [];
  bool isLoading = true;
  String? errorText;

  /// แคช uid -> username
  final Map<String, String?> usernameByUid = {};

  @override
  void initState() {
    super.initState();
    _fetchPetitions();
  }

  /// เรียก batch API: POST /api/users/usernames  body: { uids: string[] }
  Future<void> _fetchUsernamesBatch(List<String> uids) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Not authenticated');
    }

    final url = '${ApiEndpoints.baseUrl}/api/users/usernames';
    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'uids': uids}),
    );

    if (res.statusCode != 200) {
      debugPrint('fetchUsernamesBatch HTTP ${res.statusCode}: ${res.body}');
      return;
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final usernames =
        data?['usernames'] as Map<String, dynamic>?; // { uid: username|null }

    if (usernames != null) {
      usernames.forEach((k, v) {
        usernameByUid[k.trim()] = (v == null) ? null : (v as String);
      });
    }
  }

  Future<void> _fetchPetitions() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final idToken = await user.getIdToken();

      // 1) ดึงรายการคำร้อง
      final uri =
          Uri.parse('${ApiEndpoints.baseUrl}/api/actionlog/getChaningstatus');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final body = json.decode(res.body) as Map<String, dynamic>;
      final List list = (body['data'] ?? []) as List;

      petitions = list
          .map((e) => PetitionItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // 2) เรียก batch เพื่อดึง username ตาม uid (target)
      final uniqueUids = petitions.map((p) => p.target.trim()).toSet().toList();
      final uidsToFetch = uniqueUids
          .where((u) => u.isNotEmpty && !usernameByUid.containsKey(u))
          .toList();

      if (uidsToFetch.isNotEmpty) {
        await _fetchUsernamesBatch(uidsToFetch);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorText = e.toString();
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAdmin()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListuserSuspended()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListuserDeleteAdmin()),
        );
        break;
      case 3:
        // หน้าเดิม
        break;
    }
  }

  String _displayNameFor(String rawUid) {
    final uid = rawUid.trim();
    final name = usernameByUid[uid];
    return (name != null && name.isNotEmpty) ? name : uid;
  }

  @override
  Widget build(BuildContext context) {
    const appBarColor = Color(0xFF564843);
    const bgColor = Color(0xFFC98993);
    const cardColor = Color(0xFFEFEAE3);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header
          Stack(
            children: [
              Column(
                children: [
                  Container(
                    color: appBarColor,
                    height: MediaQuery.of(context).padding.top + 80,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 30,
                left: context.screenWidth / 2 - 50,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),

          // Admin badge
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: appBarColor,
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
                        'Admin',
                        style: GoogleFonts.kanit(
                            fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchPetitions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/icons/penti.png',
                                width: 35, height: 35),
                            const SizedBox(width: 8),
                            Text(
                              'รายการคำร้องของผู้ใช้',
                              style: GoogleFonts.kanit(
                                  fontSize: 22, color: appBarColor),
                            ),
                          ],
                        ),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (errorText != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'เกิดข้อผิดพลาด: $errorText',
                              style: GoogleFonts.kanit(
                                  color: Colors.red, fontSize: 16),
                            ),
                          )
                        else if (petitions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'ยังไม่มีคำร้อง',
                              style: GoogleFonts.kanit(
                                  fontSize: 18, color: appBarColor),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: petitions.length,
                            itemBuilder: (context, index) {
                              final p = petitions[index];
                              final displayName = _displayNameFor(p.target);

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: appBarColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: GoogleFonts.kanit(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        // ✅ ส่ง actionId + uid ไปหน้า DeteiluserSuspended
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DeteiluserSuspended(
                                              userName: displayName,
                                              actionId: p
                                                  .actionId, // <-- ต้องมีใน PetitionItem
                                              uid: p
                                                  .target, // เผื่อใช้ดูข้อมูลผู้ใช้
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE6D2CD),
                                        foregroundColor:
                                            const Color(0xFF564843),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        textStyle:
                                            GoogleFonts.kanit(fontSize: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        'ดูข้อมูลคำร้อง',
                                        style: GoogleFonts.kanit(
                                            fontSize: 15,
                                            color: const Color(0xFF564843)),
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
          ),
        ],
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
        selectedLabelStyle: GoogleFonts.kanit(
            fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
        unselectedLabelStyle: GoogleFonts.kanit(
            fontSize: 17, fontWeight: FontWeight.normal, color: Colors.white60),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/accout.png', width: 24, height: 24),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/deactivate.png',
                width: 30, height: 30),
            label: 'บัญชีที่ระงับ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/social-media-management.png',
                width: 24, height: 24),
            label: 'Manage',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/wishlist-heart.png',
                width: 24, height: 24),
            label: 'คำร้อง',
          ),
        ],
      ),
    );
  }
}

/// แทน MediaWidth.of(context)
extension ScreenSizeExt on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
}
