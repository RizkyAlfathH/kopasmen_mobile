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
  ScrollController _scrollController = ScrollController();
  double _headerHeight = 300.0;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4E342E).withOpacity(0.8),
                  Color(0xFF4E342E).withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(
                    color: Color(0xFF2E2E2E),
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    double opacity = 1.0 - (_scrollOffset / 200).clamp(0.0, 1.0);
    double scale = 1.0 - (_scrollOffset / 1000).clamp(0.0, 0.3);
    
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Profile Avatar with enhanced design
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF757575),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 5,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFDC16), Color(0xFFFFC107)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Name with enhanced typography
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                anggota!['nama'] ?? 'Nama tidak tersedia',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            
            // Enhanced NIP Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF4E342E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.badge,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No Anggota : ${anggota!['nomor_anggota'] ?? '-'}',
                    style: const TextStyle(
                      color: Color(0xFF4E342E),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFDC16), Color(0xFFFFC107)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E342E)),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Memuat data profil...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : anggota == null
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFDC16), Color(0xFFFFC107)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_off,
                            size: 60,
                            color: Color(0xFF4E342E),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Data profil tidak ditemukan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // Background gradient
                    Container(
                      height: _headerHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFDC16),
                            Color(0xFFFFC107),
                            Color(0xFFFFB300),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    
                    // Main scrollable content
                    CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Header section
                        SliverToBoxAdapter(
                          child: Container(
                            height: _headerHeight,
                            child: _buildHeaderContent(),
                          ),
                        ),
                        
                        // Info section
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 30),
                                
                                // Section Title with enhanced design
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF4E342E), Color(0xFF3E2723)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF4E342E).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Informasi Pribadi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Info Items
                                _buildInfoItem(
                                  'Nama Lengkap',
                                  anggota!['nama'] ?? '-',
                                  Icons.person_outline,
                                ),
                                
                                _buildInfoItem(
                                  'Nomor Induk Pegawai',
                                  anggota!['nip'] ?? '-',
                                  Icons.badge_outlined,
                                ),
                                
                                _buildInfoItem(
                                  'Jenis Kelamin',
                                  anggota!['jenis_kelamin'] ?? 'Laki-laki',
                                  Icons.people_outline,
                                ),
                                
                                _buildInfoItem(
                                  'Tanggal Bergabung',
                                  anggota!['tanggal_daftar'] ?? '01 Januari 2024',
                                  Icons.calendar_today_outlined,
                                ),
                                
                                _buildInfoItem(
                                  'Alamat Email',
                                  anggota!['email'] ?? 'ujang@gmail.com',
                                  Icons.email_outlined,
                                ),
                                
                                _buildInfoItem(
                                  'Alamat Rumah',
                                  anggota!['alamat'] ?? 'Jl. Budhi',
                                  Icons.location_on_outlined,
                                ),
                                
                                _buildInfoItem(
                                  'Nomor Telepon',
                                  anggota!['no_telp'] ?? '-',
                                  Icons.phone_outlined,
                                ),
                                
                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Floating title that appears when scrolling
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _scrollOffset > 150 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFFDC16),
                                Color(0xFFFFDC16).withOpacity(0.9),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: SafeArea(
                            child: Center(
                              child: Text(
                                anggota!['nama'] ?? 'Profile',
                                style: const TextStyle(
                                  color: Color(0xFF4E342E),
                                  fontSize: 18,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}