import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final String nomorAnggota;
  final String nama;

  const ProfilePage({
    super.key,
    required this.nomorAnggota,
    this.nama = 'User',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? anggota;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  double _headerHeight = 300.0;
  double _scrollOffset = 0.0;

  // Warna tema sesuai web
  static const Color kYellowLight = Color(0xFFFFDC16);
  static const Color kYellowMid = Color(0xFFFFC107);
  static const Color kYellowDark = Color(0xFFFFB300);
  static const Color kBrown = Color(0xFF4E342E);
  static const Color kBrownDark = Color(0xFF3E2723);
  static const Color kWhite = Colors.white;
  static const Color kBgPage = Color(0xFFF5F5F5);
  static const Color kBgSection = Color(0xFFF8F9FA);
  static const Color kTextDark = Color(0xFF2E2E2E);
  static const Color kTextGrey = Color(0xFF9E9E9E);

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
      final data = await ApiService.getProfile(widget.nomorAnggota);
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
            backgroundColor: kBrownDark,
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
        color: kWhite,
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
              gradient: const LinearGradient(
                colors: [kBrown, kBrownDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kWhite, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kTextGrey,
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
                    color: kTextDark,
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

            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kWhite,
                shape: BoxShape.circle,
                border: Border.all(color: kWhite, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.person, size: 52, color: kBrown),
              ),
            ),
            const SizedBox(height: 16),

            // Nama — putih agar terbaca di atas kuning
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                anggota!['nama'] ?? 'Nama tidak tersedia',
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 22,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Badge No Anggota — coklat gelap agar kontras di kuning
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kBrownDark,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
                      color: kYellowLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.badge,
                      size: 13,
                      color: kBrownDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No. Anggota : ${anggota!['nomor_anggota'] ?? '-'}',
                    style: const TextStyle(
                      color: kYellowLight,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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
      backgroundColor: kBgPage,
      body: isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kYellowLight, kYellowMid, kYellowDark],
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
                        color: kWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kBrown),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Memuat data profil...',
                      style: TextStyle(
                        color: kBrownDark,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 1),
                            blurRadius: 3,
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kYellowLight, kYellowMid, kYellowDark],
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
                            color: kWhite,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_off_outlined,
                            size: 56,
                            color: kBrown,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Data profil tidak ditemukan',
                          style: TextStyle(
                            color: kBrownDark,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black12,
                                offset: Offset(0, 1),
                                blurRadius: 3,
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
                    // Header background kuning gradient
                    Container(
                      height: _headerHeight,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kYellowLight, kYellowMid, kYellowDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Scrollable content
                    CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: _headerHeight,
                            child: _buildHeaderContent(),
                          ),
                        ),

                        // Info section
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.only(top: 16),
                            decoration: const BoxDecoration(
                              color: kBgSection,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 28),

                                // Section title — sesuai web: kotak coklat + teks putih
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [kBrown, kBrownDark],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kBrown.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.info_outline,
                                          color: kWhite, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Informasi Pribadi',
                                        style: TextStyle(
                                          color: kWhite,
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Info items
                                _buildInfoItem('Nama Lengkap', anggota!['nama'] ?? '-', Icons.person_outline),
                                _buildInfoItem('Nomor Induk Pegawai', anggota!['nip'] ?? '-', Icons.badge_outlined),
                                _buildInfoItem('Jenis Kelamin', anggota!['jenis_kelamin'] ?? '-', Icons.people_outline),
                                _buildInfoItem('Umur', '${anggota!['umur'] ?? '-'}', Icons.cake_outlined),
                                _buildInfoItem('Profesi', anggota!['pekerjaan'] ?? '-', Icons.work_outline),
                                _buildInfoItem('Tanggal Bergabung', anggota!['tanggal_daftar'] ?? '-', Icons.calendar_today_outlined),
                                _buildInfoItem('Alamat Email', anggota!['email'] ?? '-', Icons.email_outlined),
                                _buildInfoItem('Alamat Rumah', anggota!['alamat'] ?? '-', Icons.location_on_outlined),
                                _buildInfoItem('Nomor Telepon', anggota!['no_telp'] ?? '-', Icons.phone_outlined),

                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Floating app bar saat scroll
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _scrollOffset > 150 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          height: 90,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kYellowLight, kYellowMid],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: SafeArea(
                            child: Center(
                              child: Text(
                                anggota!['nama']?.toString() ?? 'Profil',
                                style: const TextStyle(
                                  color: kBrownDark,
                                  fontSize: 16,
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