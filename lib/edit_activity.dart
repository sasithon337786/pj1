import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pj1/constant/api_endpoint.dart';

class EditActivity extends StatefulWidget {
  final int actId;
  final String label;
  final String iconPath;
  final bool isNetworkImage;
  final String uid;

  const EditActivity({
    Key? key,
    required this.actId,
    required this.label,
    required this.iconPath,
    required this.isNetworkImage,
    required this.uid,
  }) : super(key: key);

  @override
  State<EditActivity> createState() => _EditActivityState();
}

class _EditActivityState extends State<EditActivity> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? uploadedImageUrl;
  late TextEditingController activityNameController;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    activityNameController = TextEditingController(text: widget.label);
  }

  @override
  void dispose() {
    activityNameController.dispose();
    super.dispose();
  }

  Future<String?> _uploadActivityImage(
      String userId, File selectedImage) async {
    try {
      final random = Random();
      final randomNumber = random.nextInt(90000) + 10000;
      final ref = _storage
          .ref()
          .child('activity_pics')
          .child('${userId}_$randomNumber.jpg');

      final uploadTask = ref.putFile(selectedImage);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _getUserRole(String uid) async {
    // Example: Make an API call to get the user's role
    // Replace with your actual API call
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiEndpoints.baseUrl}/api/auth/getRole?uid=$uid'), // Example API route
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role']; // Assuming the response has a 'role' field
      } else {
        print('Failed to get user role: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<void> _updateActivity() async {
    final uid = widget.uid;
    final actId = widget.actId;
    final newName = activityNameController.text;

    try {
      // โชว์ loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.black54,
            ),
          );
        },
      );

      String imageUrl = widget.iconPath;

      if (selectedImage != null) {
        final uploadedUrl = await _uploadActivityImage(uid, selectedImage!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          Navigator.pop(context);
          print('❌ อัปโหลดรูปภาพไม่สำเร็จ');
          return;
        }
      }

      String role = 'member';
      final roleResponse = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/getRole?uid=$uid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (roleResponse.statusCode == 200) {
        final roleData = jsonDecode(roleResponse.body);
        role = roleData['role'];
      }

      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (idToken == null) {/* แจ้ง error */}

      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/activity/updateAct');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken', // <-- สำคัญ
        },
        body: jsonEncode({
          'act_id': actId,
          'act_name': newName,
          'act_pic': imageUrl,
        }),
      );

      // ปิด loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        print('✅ อัปเดตกิจกรรมสำเร็จ');
        if (mounted) Navigator.pop(context, true);
      } else {
        print('❌ อัปเดตไม่สำเร็จ: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // ปิด dialog ถ้าเจอ error
      print('❌ เกิดข้อผิดพลาดระหว่างอัปเดต: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedImage = selectedImage != null
        ? Image.file(selectedImage!, fit: BoxFit.cover, width: 100, height: 100)
        : widget.isNetworkImage
            ? Image.network(widget.iconPath,
                fit: BoxFit.cover, width: 100, height: 100)
            : Image.asset(widget.iconPath,
                fit: BoxFit.cover, width: 100, height: 100);

    return Scaffold(
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
                    onTap: () {
                      Navigator.pop(context);
                    },
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

            // กล่องกรอกข้อมูล
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6D2CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset('assets/icons/magic-wand.png',
                          width: 30, height: 30),
                      const SizedBox(width: 8),
                      Text('Edit Activity',
                          style: GoogleFonts.kanit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B4436))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ปุ่มเลือกรูปภาพ
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFEAE3),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(child: displayedImage),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: activityNameController,
                    decoration: InputDecoration(
                      hintText: 'Activity Name...',
                      hintStyle: GoogleFonts.kanit(color: Colors.white),
                      filled: true,
                      fillColor: const Color(0xFF564843),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: GoogleFonts.kanit(color: Colors.white),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateActivity();
                        // TODO: Save changes
                        final newName = activityNameController.text;
                        print('New name: $newName');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF564843),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text('Save',
                          style: GoogleFonts.kanit(
                              color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
