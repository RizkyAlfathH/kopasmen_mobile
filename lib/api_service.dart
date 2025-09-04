import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api"; 

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
}
