import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // ต้องเพิ่ม import นี้เข้ามาด้วยนะ สำหรับ File

class ApiService {
  // เปลี่ยนเป็น IP ที่ backend รันอยู่
  // ถ้า backend ของหนูรองรับการอัปโหลดไฟล์ด้วย ให้แน่ใจว่า baseUrl ถูกต้องและ backend พร้อมรับไฟล์
  final String baseUrl = 'http://10.160.17.225:3000';

  Future<void> checkStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🌐 Server says: ${data['message']}');
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error checking status: $e');
      // อาจจะโยน Exception หรือจัดการ error ที่นี่
    }
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        print('✅ Login success: ${response.body}');
        return true;
      } else {
        print('❌ Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('⚠️ Error during login: $e');
      return false;
    }
  }

  // --- ฟังก์ชันใหม่สำหรับเพิ่มหมวดหมู่ ---
  Future<bool> addCategory(File imageFile, String categoryName) async {
    try {
      // ตรวจสอบว่ารูปภาพมีอยู่จริงหรือไม่
      if (!await imageFile.exists()) {
        print('❌ Error: Image file does not exist at path: ${imageFile.path}');
        return false;
      }

      // สร้าง Multipart request สำหรับส่งไฟล์
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '$baseUrl/api/categories'), // **หนูต้องเปลี่ยน endpoint นี้ให้ตรงกับที่ backend กำหนด**
      );

      // เพิ่มชื่อหมวดหมู่เป็น field
      request.fields['name'] =
          categoryName; // **หนูต้องเปลี่ยนชื่อ field 'name' ให้ตรงกับที่ backend คาดหวัง**

      // เพิ่มรูปภาพเป็นไฟล์
      request.files.add(await http.MultipartFile.fromPath(
        'categoryImage', // **หนูต้องเปลี่ยนชื่อ field 'categoryImage' ให้ตรงกับที่ backend คาดหวัง**
        imageFile.path,
      ));

      // ส่ง request
      var response = await request.send();

      // อ่าน response
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Category added successfully: $responseBody');
        return true;
      } else {
        print(
            '❌ Failed to add category. Status code: ${response.statusCode}, Body: $responseBody');
        return false;
      }
    } catch (e) {
      print('⚠️ Error adding category: $e');
      return false;
    }
  }
}
