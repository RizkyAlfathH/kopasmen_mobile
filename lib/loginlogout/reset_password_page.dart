import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController nomorAnggotaController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool anggotaValidated = false;
  bool _loading = false;
  String? _error;

  // ================= CEK NOMOR ANGGOTA =================
  void checkNomorAnggota() async {
    setState(() => _loading = true);

    String nomorAnggota = nomorAnggotaController.text.trim();
    bool exists =
        await ApiService.checkNomorAnggota(nomorAnggota);

    setState(() => _loading = false);

    if (exists) {
      setState(() {
        anggotaValidated = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = "Nomor Anggota tidak ditemukan";
      });
    }
  }

  // ================= RESET PASSWORD =================
  void resetPassword() async {
    String newPassword = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = "Password tidak boleh kosong");
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _error = "Password tidak sama");
      return;
    }

    setState(() => _loading = true);

    bool success = await ApiService.resetPassword(
      nomorAnggotaController.text.trim(),
      newPassword,
    );

    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Password berhasil direset, silakan login"),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() => _error = "Gagal reset password");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF5C842),
              const Color(0xFFFFD700),
              const Color(0xFFF5C842).withOpacity(0.9),
              const Color(0xFFFFD700).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // BACK BUTTON
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black87,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, '/login');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Kembali ke Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // LOGO
                  Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Image.asset(
                        'assets/images/logo_smea.jpg',
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Icon(Icons.school,
                              size: 50);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Reset Password",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 50),

                  // CARD
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text("Nomor Anggota"),
                          const SizedBox(height: 10),

                          _inputField(
                            controller:
                                nomorAnggotaController,
                            hint:
                                "Masukkan Nomor Anggota...",
                            icon:
                                Icons.person_outline,
                            enabled:
                                !anggotaValidated,
                          ),

                          if (!anggotaValidated) ...[
                            const SizedBox(height: 20),
                            _actionButton(
                              "Cek Nomor Anggota",
                              checkNomorAnggota,
                            ),
                          ],

                          if (anggotaValidated) ...[
                            const SizedBox(height: 24),
                            const Text("Password Baru"),
                            const SizedBox(height: 10),
                            _inputField(
                              controller:
                                  passwordController,
                              hint:
                                  "Masukkan password baru...",
                              icon:
                                  Icons.lock_outline,
                              obscure: true,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                                "Konfirmasi Password"),
                            const SizedBox(height: 10),
                            _inputField(
                              controller:
                                  confirmPasswordController,
                              hint:
                                  "Ulangi password...",
                              icon:
                                  Icons.lock_reset,
                              obscure: true,
                            ),
                            const SizedBox(height: 30),
                            _actionButton(
                              "Reset Password",
                              resetPassword,
                            ),
                          ],

                          const SizedBox(height: 20),

                          if (_error != null)
                            Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= WIDGET INPUT =================
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ================= BUTTON =================
  Widget _actionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const CircularProgressIndicator()
            : Text(text),
      ),
    );
  }
}
//