import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _nomorAnggotaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _anggotaValidated = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  void _checkNomorAnggota() async {
    setState(() { _loading = true; _error = null; });
    final exists = await ApiService.checkNomorAnggota(
        _nomorAnggotaController.text.trim());
    setState(() => _loading = false);
    if (exists) {
      setState(() => _anggotaValidated = true);
    } else {
      setState(() => _error = "Nomor Anggota tidak ditemukan");
    }
  }

  void _resetPassword() async {
    final newPass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _error = "Password tidak boleh kosong");
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _error = "Konfirmasi password tidak sama");
      return;
    }

    setState(() { _loading = true; _error = null; });
    final success = await ApiService.resetPassword(
        _nomorAnggotaController.text.trim(), newPass);
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password berhasil direset, silakan login")),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80, left: -80,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
            ),
            Positioned(
              bottom: -60, right: -60,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Tombol kembali
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  color: Colors.black87, size: 18),
                              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Kembali ke Login",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Logo
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8), // ← sedikit padding agar logo tidak mentok pinggir
                        child: Image.asset(
                          'assets/images/logo_smea.jpg',
                          fit: BoxFit.contain,  // ← logo tampil penuh, tidak di-crop
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "KOPASMEN",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: Color(0xFF291B18),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Reset Password Akun Anda",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.13),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Reset Password",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1a1a1a),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Indikator terverifikasi
                              if (_anggotaValidated) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe8f5e9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          color: Color(0xFF2e7d32), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Nomor anggota terverifikasi",
                                        style: TextStyle(
                                          color: const Color(0xFF2e7d32),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              _buildLabel("Nomor Anggota"),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _nomorAnggotaController,
                                hint: "Masukkan Nomor Anggota...",
                                icon: Icons.person_outline,
                                enabled: !_anggotaValidated,
                              ),

                              if (!_anggotaValidated) ...[
                                const SizedBox(height: 20),
                                _buildButton("Cek Nomor Anggota", _checkNomorAnggota),
                              ],

                              if (_anggotaValidated) ...[
                                const SizedBox(height: 16),
                                _buildLabel("Password Baru"),
                                const SizedBox(height: 6),
                                _buildPasswordField(
                                  controller: _passwordController,
                                  hint: "Masukkan password baru...",
                                  obscure: _obscurePassword,
                                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                const SizedBox(height: 16),
                                _buildLabel("Konfirmasi Password"),
                                const SizedBox(height: 6),
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  hint: "Ulangi password...",
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                const SizedBox(height: 24),
                                _buildButton("Reset Password", _resetPassword),
                              ],

                              // Error
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFffe5e5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Color(0xFFd93025), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFFd93025),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1a1a1a)),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFaaaaaa), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 18),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFf5f5f5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFcccccc), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFcccccc), width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe0e0e0), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFaaaaaa), fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF888888), size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFF888888), size: 18,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFcccccc), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFcccccc), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2)),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: const Color(0xFF291B18),
          disabledBackgroundColor: const Color(0xFFFFD700).withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF291B18))))
            : Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}