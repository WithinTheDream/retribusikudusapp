import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/login'),
        headers: ApiClient.headers,
        body: jsonEncode({'email_or_username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        await prefs.setString('role', data['data']['user']['role']);
        await prefs.setString('nama', data['data']['user']['nama_lengkap']);

        return {'success': true, 'role': data['data']['user']['role']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login Gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse('${ApiClient.baseUrl}/logout'),
          headers: {...ApiClient.headers, 'Authorization': 'Bearer $token'},
        );
      } catch (e) {
        // Abaikan error jaringan saat logout
      }
    }

    await prefs.clear();
  }
}
