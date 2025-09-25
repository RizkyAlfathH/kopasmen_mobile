import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // ======================
  // AUTH
  // ======================

  // Login
  static Future<Map<String, dynamic>?> login(
    String nomorAnggota,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/login/");
    try { 
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nomor_anggota": nomorAnggota,
          "password": password,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return body;
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        return {"error": body["error"] ?? "Login gagal"};
      } else {
        return {"error": "Terjadi kesalahan server (${response.statusCode})"};
      }
    } catch (e) {
      return {"error": "Terjadi kesalahan: $e"};
    }
  }

  // Cek NIP / Nomor Anggota
  static Future<bool> checkNomorAnggota(String nomorAnggota) async {
    final url = Uri.parse("$baseUrl/check-nomor-anggota/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nomor_anggota": nomorAnggota}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] == true;
    } else {
      return false;
    }
  }

  // Reset Password
  static Future<bool> resetPassword(String nomorAnggota, String newPassword) async {
    final url = Uri.parse("$baseUrl/reset-password/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nomor_anggota": nomorAnggota,
        "password": newPassword,
      }),
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