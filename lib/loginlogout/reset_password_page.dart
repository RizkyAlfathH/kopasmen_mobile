import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController nipController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool nipValidated = false;

  void checkNIP() async {
    String nip = nipController.text.trim();
    bool exists = await ApiService.checkNIP(nip);
    if (exists) {
      setState(() {
        nipValidated = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("NIP tidak ditemukan")),
      );
    }
  }

  void resetPassword() async {
    String newPassword = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password tidak boleh kosong")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password tidak sama")),
      );
      return;
    }

    bool success = await ApiService.resetPassword(nipController.text.trim(), newPassword);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password berhasil direset, silakan login")),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal reset password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nipController,
              decoration: InputDecoration(labelText: "NIP"),
              enabled: !nipValidated,
            ),
            if (!nipValidated)
              ElevatedButton(
                onPressed: checkNIP,
                child: Text("Cek NIP"),
              ),
            if (nipValidated) ...[
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password Baru"),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Konfirmasi Password"),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: resetPassword,
                child: Text("Reset Password"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
