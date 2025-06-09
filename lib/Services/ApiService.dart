import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://10.160.17.225:3000'; // เปลี่ยนเป็น IP ที่ backend รันอยู่

  Future<void> checkStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('🌐 Server says: ${data['message']}');
    } else {
      throw Exception('Server responded with status: ${response.statusCode}');
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
}
