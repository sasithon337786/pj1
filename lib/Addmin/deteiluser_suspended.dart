import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:pj1/Addmin/list_admin.dart';
import 'package:pj1/Addmin/listuser_delete_admin.dart';
import 'package:pj1/Addmin/listuser_suspended.dart';
import 'package:pj1/Addmin/main_Addmin.dart';
import 'package:pj1/constant/api_endpoint.dart';

class DeteiluserSuspended extends StatefulWidget {
  final String userName;
  final int actionId; // ใช้โหลดรายละเอียด
  final String? uid; // เผื่อใช้ปุ่มดูข้อมูลผู้ใช้

  const DeteiluserSuspended({
    Key? key,
    required this.userName,
    required this.actionId,
    this.uid,
  }) : super(key: key);

  @override
  State<DeteiluserSuspended> createState() => _DeteiluserSuspendedState();
}

class _DeteiluserSuspendedState extends State<DeteiluserSuspended> {
  final Color primaryColor = const Color(0xFFEFEAE3);

  final Color secondaryColor = const Color(0xFF564843);
  final Color backgroundColor = const Color(0xFFC98993);
  final Color accentColor = const Color(0xFFE6D2CD);
  final Color lightTextColor = Colors.white;

  bool isLoading = true;
  String? errorText;

  /// เก็บรายละเอียด action_log ที่โหลดมา
  Map<String, dynamic>?
      detail; // { action_id, target, action, reason, action_by, create_at }

  @override
  void initState() {
    super.initState();
    _fetchActionDetail();
  }

  Future<void> _fetchActionDetail() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Not authenticated');
      }
      final url =
          '${ApiEndpoints.baseUrl}/api/actionlog/getDetaillog/${widget.actionId}';

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Empty data');

      setState(() {
        detail = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorText = e.toString();
        isLoading = false;
      });
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionText = detail?['action']?.toString() ?? '-';
    final reasonText = (detail?['reason']?.toString() ?? '').trim();
    final targetUid = detail?['target']?.toString() ?? (widget.uid ?? '-');
    final actionBy = detail?['action_by']?.toString() ?? '-';
    final createdAt = _fmtDate(detail?['create_at']?.toString());

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    Container(
                      color: secondaryColor,
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/icons/petition.png',
                            width: 35, height: 35),
                        const SizedBox(width: 6),
                        Text(
                          'คำร้อง',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.userName,
                            style: GoogleFonts.kanit(
                              fontSize: 20,
                              color: secondaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Loading / Error / Content
                    if (isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child:
                              CircularProgressIndicator(color: secondaryColor),
                        ),
                      )
                    else if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'เกิดข้อผิดพลาด: $errorText',
                          style: GoogleFonts.kanit(
                              color: Colors.red, fontSize: 16),
                        ),
                      )
                    else ...[
                      // _kv('Action ID', '#${widget.actionId}'),
                      _kv('สถานะ (action)', actionText),
                      // _kv('ผู้ร้อง (UID)', targetUid),
                      // _kv('ผู้ดำเนินการ', actionBy),
                      _kv('วันที่สร้าง', createdAt),
                      const SizedBox(height: 12),
                      _kv(
                          'เหตุผล',
                          reasonText.isNotEmpty
                              ? reasonText
                              : '— ไม่มีข้อความเหตุผล —'),
                    ],

                    const SizedBox(height: 30),
                    // Center(
                    //   child: ElevatedButton.icon(
                    //     onPressed: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (_) =>
                    //               const ListUserInfoScreen(), // ไม่ต้องส่งอะไร
                    //         ),
                    //       );
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: secondaryColor,
                    //       foregroundColor: lightTextColor,
                    //       padding: const EdgeInsets.symmetric(
                    //           horizontal: 20, vertical: 10),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(20),
                    //       ),
                    //       textStyle: GoogleFonts.kanit(fontSize: 16),
                    //     ),
                    //     icon: Image.asset('assets/icons/account.png',
                    //         width: 24, height: 24),
                    //     label: const Text('ข้อมูลผู้ใช้'),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// แสดงคู่ข้อมูล label : value
  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: const Color(0xFF3E3E3E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
