import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Login
  static Future<Map<String, dynamic>?> login(String nip, String password) async {
    final url = Uri.parse("$baseUrl/login/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nip": nip, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"error": jsonDecode(response.body)};
    }
  }

  // Cek NIP
  static Future<bool> checkNIP(String nip) async {
    final url = Uri.parse("$baseUrl/check-nip/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nip": nip}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] == true;
    } else {
      return false;
    }
  }

  // Reset Password
  static Future<bool> resetPassword(String nip, String newPassword) async {
    final url = Uri.parse("$baseUrl/reset-password/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nip": nip, "password": newPassword}),
    );

    return response.statusCode == 200;
  }

  // Ambil daftar simpanan berdasarkan NIP
  static Future<List<dynamic>> getSimpanan(String nip) async {
    final url = Uri.parse("$baseUrl/$nip/simpan/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data simpanan");
    }
  }

  // Ambil daftar penarikan berdasarkan NIP
  static Future<List<dynamic>> getPenarikan(String nip) async {
    final url = Uri.parse("$baseUrl/$nip/tarik/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data penarikan");
    }
  }
}
