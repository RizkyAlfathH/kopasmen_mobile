import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final String nip;
  const ProfilePage({super.key, required this.nip});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? anggota;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ApiService.getProfile(widget.nip);
      setState(() {
        anggota = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFF4E342E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFF4E342E),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(
                    color: Color(0xFF3E2723),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDC16),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E342E)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data profil...',
                    style: TextStyle(
                      color: Color(0xFF4E342E),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : anggota == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.person_off,
                          size: 48,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Data profil tidak ditemukan',
                        style: TextStyle(
                          color: Color(0xFF4E342E),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          children: [
                            // Title
                            Text(
                              'Profile',
                              style: TextStyle(
                                color: Color(0xFF4E342E),
                                fontSize: 24,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            // Profile Avatar with Camera Icon
                            Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFDC16),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Color(0xFF4E342E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Name
                            Text(
                              anggota!['nama'] ?? 'Nama tidak tersedia',
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontSize: 20,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            
                            // NIP Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFDC16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Color(0xFF4E342E), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.badge,
                                    size: 16,
                                    color: Color(0xFF4E342E),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'NIP : ${anggota!['nip'] ?? '-'}',
                                    style: const TextStyle(
                                      color: Color(0xFF4E342E),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Info Card Section
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                
                                // Section Title
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Informasi Pribadi',
                                    style: TextStyle(
                                      color: Color(0xFF4E342E),
                                      fontSize: 18,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Info Items
                                _buildInfoItem(
                                  'Nama',
                                  anggota!['nama'] ?? '-',
                                  Icons.person,
                                ),
                                const Divider(height: 1, indent: 60),
                                
                                _buildInfoItem(
                                  'NIP',
                                  anggota!['nip'] ?? '-',
                                  Icons.badge,
                                ),
                                const Divider(height: 1, indent: 60),
                                
                                _buildInfoItem(
                                  'Jenis Kelamin',
                                  anggota!['jenis_kelamin'] ?? 'Laki-laki',
                                  Icons.people,
                                ),
                                const Divider(height: 1, indent: 60),
                                
                                _buildInfoItem(
                                  'Tanggal Daftar',
                                  anggota!['tanggal_daftar'] ?? '01 Januari 2024',
                                  Icons.calendar_today,
                                ),
                                const Divider(height: 1, indent: 60),
                                
                                _buildInfoItem(
                                  'Email',
                                  anggota!['email'] ?? 'ujang@gmail.com',
                                  Icons.email,
                                ),
                                const Divider(height: 1, indent: 60),
                                
                                _buildInfoItem(
                                  'Alamat',
                                  anggota!['alamat'] ?? 'Jl. Budhi',
                                  Icons.location_on,
                                ),
                                const Divider(height: 1, indent: 60),
                                
                                _buildInfoItem(
                                  'No Telepon',
                                  anggota!['no_telp'] ?? '-',
                                  Icons.phone,
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
}