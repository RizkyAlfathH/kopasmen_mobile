import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // kalau di emulator Android ganti 127.0.0.1 jadi 10.0.2.2
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // ======================
  // AUTH
  // ======================

  // Login
  static Future<Map<String, dynamic>?> login(
    String nip,
    String password,
  ) async {
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

  // ======================
  // SIMPANAN & PENARIKAN
  // ======================

  // Ambil daftar simpanan berdasarkan NIP
  static Future<List<dynamic>> getSimpanan(String nip) async {
    final url = Uri.parse("$baseUrl/$nip/simpanan/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data simpanan (${response.statusCode})");
    }
  }

  // Ambil daftar penarikan berdasarkan NIP
  static Future<List<dynamic>> getPenarikan(String nip) async {
    final url = Uri.parse("$baseUrl/$nip/tarik/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data penarikan (${response.statusCode})");
    }
  }

  // ======================
  // PINJAMAN & ANGSURAN
  // ======================

  // Ambil daftar pinjaman berdasarkan NIP
  static Future<List<dynamic>> getPinjaman(String nip) async {
    final url = Uri.parse("$baseUrl/$nip/pinjaman/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data pinjaman (${response.statusCode})");
    }
  }

  // Ambil daftar angsuran berdasarkan ID pinjaman
  static Future<List<dynamic>> getAngsuran(int idPinjaman) async {
    final url = Uri.parse("$baseUrl/angsuran/$idPinjaman/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data angsuran (${response.statusCode})");
    }
  }

  // ======================
  // PROFILE
  // ======================

  // Ambil profil anggota berdasarkan NIP
  static Future<Map<String, dynamic>> getProfile(String nip) async {
    final url = Uri.parse("$baseUrl/profil/$nip/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data profil (${response.statusCode})");
    }
  }

  // Update profil anggota
  static Future<bool> updateProfile(
    String nip, {
    String? email,
    String? alamat,
    String? noTelp,
  }) async {
    final url = Uri.parse("$baseUrl/profil/$nip/update/");
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "alamat": alamat,
        "no_telp": noTelp,
      }),
    );

    return response.statusCode == 200;
  }
}
