import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../page/home_page.dart';
import 'reset_password_page.dart'; // ✅ import halaman reset password

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nipController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ApiService.login(
      _nipController.text,
      _passwordController.text,
    );

    setState(() => _loading = false);

    if (result != null && result["data"] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(user: result["data"]),
        ),
      );
    } else {
      setState(() {
        _error = result?["error"]?["error"] ?? "Login gagal";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Anggota")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nipController,
              decoration: const InputDecoration(labelText: "NIP"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text("Login"),
                  ),
            const SizedBox(height: 12),

            // ✅ Tambahin tombol "Lupa Password?"
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResetPasswordPage(),
                  ),
                );
              },
              child: const Text(
                "Lupa Password?",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
