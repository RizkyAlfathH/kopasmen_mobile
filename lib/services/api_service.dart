import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // ======================
  // AUTH
  // ======================

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

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {"error": "Format response tidak valid"};
        }
      }

      if (decoded is Map && decoded["error"] != null) {
        final err = decoded["error"];
        if (err is List) {
          return {"error": err.join(", ")};
        } else {
          return {"error": err.toString()};
        }
      }

      return {"error": "Login gagal (${response.statusCode})"};
    } catch (e) {
      return {"error": "Terjadi kesalahan: $e"};
    }
  }

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

  static Future<bool> resetPassword(
    String nomorAnggota,
    String newPassword,
  ) async {
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

  static Future<List<dynamic>> getSimpanan(String nomorAnggota) async {
    final encoded = Uri.encodeComponent(nomorAnggota.trim());
    final url = Uri.parse("$baseUrl/simpanan/$encoded/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data simpanan (${response.statusCode})");
    }
  }

  static Future<List<dynamic>> getPenarikan(String nip) async {
    final encoded = Uri.encodeComponent(nip.trim());
    final url = Uri.parse("$baseUrl/tarik/$encoded/");
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

  static Future<List<dynamic>> getPinjaman(String nip) async {
    final encoded = Uri.encodeComponent(nip.trim());
    final url = Uri.parse("$baseUrl/pinjaman/$encoded/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data pinjaman (${response.statusCode})");
    }
  }

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
  // PROFIL
  // ======================

  static Future<Map<String, dynamic>> getProfile(String nomorAnggota) async {
    final encoded = Uri.encodeComponent(nomorAnggota.trim());
    final url = Uri.parse("$baseUrl/profil/$encoded/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal ambil data profil (${response.statusCode})");
    }
  }

  static Future<bool> updateProfile(
    String nomorAnggota, {
    String? nip,
    String? email,
    String? alamat,
    String? noTelp,
  }) async {
    final encoded = Uri.encodeComponent(nomorAnggota.trim());
    final url = Uri.parse("$baseUrl/profil/$encoded/update/");
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nip": nip,
        "email": email,
        "alamat": alamat,
        "no_telp": noTelp,
      }),
    );

    return response.statusCode == 200;
  }
}