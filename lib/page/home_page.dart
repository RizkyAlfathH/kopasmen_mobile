import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pinjaman_page.dart';
import 'tabungan_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 2;
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  double totalPinjaman = 0;
  double tagihanBulanIni = 0;
  double pokok = 0;
  double wajib = 0;
  double sukarela = 0;

  // Warna tema sesuai web
  static const Color kYellowLight = Color(0xFFFFDC16);
  static const Color kYellowMid   = Color(0xFFFFC107);
  static const Color kYellowDark  = Color(0xFFFFB300);
  static const Color kBrown       = Color(0xFF4E342E);
  static const Color kBrownDark   = Color(0xFF3E2723);
  static const Color kWhite       = Colors.white;
  static const Color kBgPage      = Color(0xFFF5F5F5);
  static const Color kTextGrey    = Color(0xFF757575);
  static const Color kGreen       = Color(0xFF2E7D32);
  static const Color kBlue        = Color(0xFF1565C0);
  static const Color kPurple      = Color(0xFF6A1B9A);
  static const Color kRed         = Color(0xFFC62828);

  double _hitungNetSimpanan(List simpanan, List penarikan, String jenis) {
    double total = 0;
    for (var s in simpanan) {
      final nama = s['jenis_simpanan']?['nama_jenis']?.toString().toLowerCase() ?? '';
      if (nama.contains(jenis.toLowerCase())) {
        total += double.tryParse(s['nominal'].toString()) ?? 0;
      }
    }
    for (var p in penarikan) {
      final nama = p['jenis_simpanan']?['nama_jenis']?.toString().toLowerCase() ?? '';
      if (nama.contains(jenis.toLowerCase())) {
        total -= double.tryParse(p['nominal'].toString()) ?? 0;
      }
    }
    return total < 0 ? 0 : total;
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return "0";
    final number = num.tryParse(value.toString()) ?? 0;
    return NumberFormat("#,##0", "id_ID").format(number);
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "-";
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final nomorAnggota = widget.user['nomor_anggota'].toString();
      final simpanan  = await ApiService.getSimpanan(nomorAnggota);
      final pinjaman  = await ApiService.getPinjaman(nomorAnggota);
      final penarikan = await ApiService.getPenarikan(nomorAnggota);

      setState(() {
        pokok    = _hitungNetSimpanan(simpanan, penarikan, "pokok");
        wajib    = _hitungNetSimpanan(simpanan, penarikan, "wajib");
        sukarela = _hitungNetSimpanan(simpanan, penarikan, "sukarela");

        totalPinjaman = pinjaman.fold(
          0.0,
          (sum, p) => sum + (double.tryParse(p['jumlah_pinjaman'].toString()) ?? 0),
        );

        tagihanBulanIni = pinjaman.fold(
          0.0,
          (sum, p) {
            if (p['status'] == 'aktif') {
              sum += double.tryParse(p['angsuran_per_bulan'].toString()) ?? 0;
            }
            return sum;
          },
        );
      });

      _animationController.forward();
    } catch (e) {
      debugPrint("Error load home data: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final nomorAnggota = widget.user['nomor_anggota'];
    final nama = widget.user['nama'] ?? '';

    final pages = [
      TabunganPage(nomorAnggota: nomorAnggota, nama: nama),
      PinjamanPage(nomorAnggota: nomorAnggota, nama: nama),
      _buildHomeContent(),
      HistoryPage(nomorAnggota: nomorAnggota, nama: nama),
      ProfilePage(nomorAnggota: nomorAnggota),
    ];

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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kBrown),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat data...',
                      style: TextStyle(
                        color: kBrownDark,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : pages[_currentIndex],

      // Bottom nav — kuning aktif, abu tidak aktif
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: kWhite,
          selectedItemColor: kBrown,
          unselectedItemColor: const Color(0xFF9E9E9E),
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.savings_outlined),
              activeIcon: Icon(Icons.savings),
              label: "Simpanan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: "Pinjaman",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  // ─── HOME CONTENT ─────────────────────────────────────────────────────────

  Widget _buildHomeContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: kBrown,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildQuickStats(),
              const SizedBox(height: 24),
              _buildSimpananSection(),
              const SizedBox(height: 24),
              _buildPinjamanSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // Header — kuning gradient 3 stop, teks coklat gelap persis web
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kYellowLight, kYellowMid, kYellowDark],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris logo + nama koperasi
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: kWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/images/logo_smea.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school,
                          size: 26,
                          color: kBrown,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "KOPASMEN",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kBrownDark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Koperasi Pegawai SMEA Negeri",
                        style: TextStyle(
                          fontSize: 11,
                          color: kBrown.withOpacity(0.7),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Card info user — putih bersih di atas kuning
              _buildUserInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar kuning
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kYellowLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.person, color: kBrownDark, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user['nama'] ?? "-",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kBrownDark,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "No. Anggota: ${widget.user['nomor_anggota'] ?? '-'}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextGrey,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Badge status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kYellowLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Anggota",
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: kBrownDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick stats — 2 kartu putih bersih
  Widget _buildQuickStats() {
    final totalSimpanan = pokok + wajib + sukarela;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.account_balance_wallet,
              title: "Total Simpanan",
              amount: "Rp ${_formatCurrency(totalSimpanan)}",
              color: kGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.credit_card,
              title: "Total Pinjaman",
              amount: "Rp ${_formatCurrency(totalPinjaman)}",
              color: kBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: kTextGrey,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // Section header — icon + teks coklat
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kYellowLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: kBrown),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kBrown,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // Simpanan section — kartu horizontal scroll
  Widget _buildSimpananSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Rincian Simpanan", Icons.savings),
        const SizedBox(height: 14),
        SizedBox(
          height: 175,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildSimpananCard(Icons.account_balance, "Simpanan Pokok", pokok, kGreen),
              _buildSimpananCard(Icons.savings, "Simpanan Wajib", wajib, kBlue),
              _buildSimpananCard(Icons.volunteer_activism, "Simpanan Sukarela", sukarela, kPurple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpananCard(IconData icon, String title, double saldo, Color color) {
    return Container(
      width: 185,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          Text(
            "Rp ${_formatCurrency(saldo)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Saldo tersedia',
            style: TextStyle(
              color: color.withOpacity(0.6),
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Pinjaman section — card coklat-kuning sesuai tema web
  Widget _buildPinjamanSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Informasi Pinjaman", Icons.credit_card),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kYellowLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: kYellowLight.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card pinjaman
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kYellowLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.credit_card, color: kBrownDark, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Status Pinjaman Anda",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kBrownDark,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Total yang telah dipinjam',
                            style: TextStyle(
                              color: kBrown.withOpacity(0.6),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                Divider(color: kYellowLight.withOpacity(0.5), thickness: 1),
                const SizedBox(height: 14),

                // Total pinjaman & tagihan
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Pinjaman",
                            style: TextStyle(
                              fontSize: 12,
                              color: kTextGrey,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rp ${_formatCurrency(totalPinjaman)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kBrown,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: kYellowLight,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Tagihan Bulan Ini",
                            style: TextStyle(
                              fontSize: 12,
                              color: kTextGrey,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rp ${_formatCurrency(tagihanBulanIni)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kRed,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
//