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

  double pokok = 0, wajib = 0, sukarela = 0;
  double totalPinjaman = 0, tagihanBulanIni = 0;
  List<Map<String, dynamic>> _history = [];

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
    
    print("User login: ${widget.user}");
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
      final simpanan = await ApiService.getSimpanan(widget.user['nip']);
      final pinjaman = await ApiService.getPinjaman(widget.user['nip']);
      final penarikan = await ApiService.getPenarikan(widget.user['nip']);

      if (!mounted) return;

      print("Jumlah simpanan: ${simpanan.length}");
      print("Jumlah pinjaman: ${pinjaman.length}");
      print("Jumlah penarikan: ${penarikan.length}");

      // Hitung total simpanan
      pokok = _sumSimpananByJenis(simpanan, "Simpanan Pokok");
      wajib = _sumSimpananByJenis(simpanan, "Simpanan Wajib");
      sukarela = _sumSimpananByJenis(simpanan, "Simpanan Sukarela");

      // Hitung total pinjaman & tagihan bulan ini
      totalPinjaman = 0;
      tagihanBulanIni = 0;
      for (var p in pinjaman) {
        totalPinjaman += double.tryParse(p['jumlah_pinjaman'].toString()) ?? 0;
        tagihanBulanIni += double.tryParse(p['angsuran_per_bulan'].toString()) ?? 0;
      }

      // Build comprehensive history
      List<Map<String, dynamic>> history = [];

      // --- Simpanan Setoran ---
      for (var s in simpanan) {
        history.add({
          "icon": Icons.savings,
          "title": "Setoran ${s['jenis_simpanan']?['nama_jenis'] ?? 'Simpanan'}",
          "date": _formatDate(s['tanggal_menyimpan'] ?? ""),
          "amount": "+ Rp ${_formatCurrency(s['nominal'])}",
          "isPositive": true,
          "tanggal": s['tanggal_menyimpan'] ?? "",
          "type": "simpanan_setoran",
        });
      }

      // --- Penarikan Simpanan ---
      for (var t in penarikan) {
        history.add({
          "icon": Icons.money_off,
          "title": "Penarikan ${t['jenis_simpanan']?['nama_jenis'] ?? 'Simpanan'}",
          "date": _formatDate(t['tanggal_tarik'] ?? ""),
          "amount": "- Rp ${_formatCurrency(t['nominal'])}",
          "isPositive": false,
          "tanggal": t['tanggal_tarik'] ?? "",
          "type": "simpanan_penarikan",
        });
      }

      // --- Pinjaman ---
      for (var p in pinjaman) {
        // Pencairan
        history.add({
          "icon": Icons.credit_card,
          "title": "Pencairan ${p['jenis_pinjaman']?['nama_jenis'] ?? 'Pinjaman'}",
          "date": _formatDate(p['tanggal_meminjam'] ?? ""),
          "amount": "+ Rp ${_formatCurrency(p['jumlah_pinjaman'])}",
          "isPositive": true,
          "tanggal": p['tanggal_meminjam'] ?? "",
          "type": "pinjaman_pencairan",
        });

        // Angsuran (ambil dari nested field kalau ada)
        final angsuranList = p['angsuran_set'] ?? p['angsuran'] ?? [];
        for (var a in angsuranList) {
          history.add({
            "icon": Icons.payment,
            "title": "Pembayaran Angsuran",
            "date": _formatDate(a['tanggal_bayar'] ?? a['tanggal_pembayaran'] ?? ""),
            "amount": "- Rp ${_formatCurrency(a['jumlah_bayar'] ?? a['nominal'])}",
            "isPositive": false,
            "tanggal": a['tanggal_bayar'] ?? a['tanggal_pembayaran'] ?? "",
            "type": "pinjaman_pembayaran",
          });
        }
      }

      history.sort((a, b) {
        final tglA = a['tanggal']?.toString();
        final tglB = b['tanggal']?.toString();

        final dateA = DateTime.tryParse(tglA ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(tglB ?? '') ?? DateTime(1970);

        return dateB.compareTo(dateA);
      });

      if (mounted) {
          setState(() {
            _history = history.take(5).toList();
          });
        }

        _animationController.forward();
      } catch (e) {
        print("Error load home data: $e");
      }

      if (mounted) {
        setState(() => isLoading = false);
      }
    }

  double _sumSimpananByJenis(List data, String jenis) {
    return data
        .where((s) => s['jenis_simpanan']['nama_jenis'] == jenis)
        .fold(0.0, (sum, s) => sum + (double.tryParse(s['nominal'].toString()) ?? 0));
  }

  String _formatCurrency(dynamic val) {
    final f = NumberFormat.decimalPattern("id");
    return f.format(double.tryParse(val.toString()) ?? 0);
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return DateFormat("dd MMM yyyy", "id").format(d);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TabunganPage(
        nip: widget.user['nip'],
        nama: widget.user['nama'],
      ),
      PinjamanPage(
        nip: widget.user['nip'],
        nama: widget.user['nama'],
      ),
      _buildHomeContent(), // halaman home
      HistoryPage(
        nip: widget.user['nip'],
        nama: widget.user['nama'],
      ),
      ProfilePage(nip: widget.user['nip']),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFDC16)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data...',
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
          : pages[_currentIndex],
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
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFFDC16),
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
              label: "Simpanan"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: "Pinjaman"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: "History"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profile"
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Home content dengan design yang diseragamkan
  Widget _buildHomeContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFFFDC16),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header yang diseragamkan dengan halaman lain
              _buildConsistentHeader(),
              
              const SizedBox(height: 20),
              
              // Quick Stats Cards
              _buildQuickStats(),
              
              const SizedBox(height: 24),

              // Simpanan Section
              _buildSimpananSection(),

              const SizedBox(height: 24),

              // Pinjaman Section
              _buildPinjamanSection(),

              const SizedBox(height: 24),

              // History Section
              _buildHistorySection(),
              
              const SizedBox(height: 100), // Bottom padding for navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsistentHeader() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFDC16),
            Color(0xFFFFE554),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card dengan style yang sama seperti halaman lain
              Container(
                width: double.infinity,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFDC16), Color(0xFFFFE554)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFFDC16).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF4E342E),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user['nama'] ?? "-",
                              style: const TextStyle(
                                color: Color(0xFF3E2723),
                                fontSize: 18,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.badge,
                                    size: 14,
                                    color: Color(0xFF757575),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'NIP: ${widget.user['nip'] ?? '-'}',
                                    style: const TextStyle(
                                      color: Color(0xFF757575),
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.credit_card,
              title: "Total Pinjaman",
              amount: "Rp ${_formatCurrency(totalPinjaman)}",
              color: const Color(0xFF1976D2),
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
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                color: Color(0xFF757575),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpananSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Rincian Simpanan", Icons.savings),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildConsistentSimpananCard(
                Icons.account_balance,
                "Simpanan Pokok",
                pokok,
                const Color(0xFF2E7D32),
              ),
              _buildConsistentSimpananCard(
                Icons.savings,
                "Simpanan Wajib",
                wajib,
                const Color(0xFF1976D2),
              ),
              _buildConsistentSimpananCard(
                Icons.volunteer_activism,
                "Simpanan Sukarela",
                sukarela,
                const Color(0xFF7B1FA2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinjamanSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Informasi Pinjaman", Icons.credit_card),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1976D2).withOpacity(0.1),
                  Color(0xFF1976D2).withOpacity(0.05),
                ],
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 2, color: Color(0xFF1976D2).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1976D2),
                              Color(0xFF1976D2).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF1976D2).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.credit_card,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Status Pinjaman Anda",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1976D2),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total yang telah dipinjam',
                              style: TextStyle(
                                color: Color(0xFF1976D2).withOpacity(0.7),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Pinjaman",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rp ${_formatCurrency(totalPinjaman)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1976D2),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: Color(0xFF1976D2).withOpacity(0.3),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Tagihan Bulan Ini",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rp ${_formatCurrency(tagihanBulanIni)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD32F2F),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader("Aktivitas Terbaru", Icons.history),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 3),
              child: const Text(
                "Lihat Semua",
                style: TextStyle(
                  color: Color(0xFFFFDC16),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_history.isEmpty)
          Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Belum ada aktivitas",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Transaksi terbaru akan muncul di sini",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                )
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (context, index) => Container(
                height: 1,
                color: Color(0xFFF5F5F5),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              itemBuilder: (context, index) {
                final h = _history[index];
                return _buildActivityItem(h, index == _history.length - 1);
              },
            ),
          ),
      ],
    ),
  );
}

Widget _buildActivityItem(Map<String, dynamic> activity, bool isLast) {
  final isPositive = activity['isPositive'] as bool;
  final type = activity['type'] as String;
  
  // Determine colors and icons based on activity type
  Color getTypeColor() {
    switch (type) {
      case 'simpanan_setoran':
        return const Color(0xFF4CAF50);
      case 'simpanan_penarikan':
        return const Color(0xFFFF9800);
      case 'pinjaman_pencairan':
        return const Color(0xFF2196F3);
      case 'pinjaman_pembayaran':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData getTypeIcon() {
    switch (type) {
      case 'simpanan_setoran':
        return Icons.savings;
      case 'simpanan_penarikan':
        return Icons.money_off;
      case 'pinjaman_pencairan':
        return Icons.credit_card;
      case 'pinjaman_pembayaran':
        return Icons.payment;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String getActivityDescription() {
    switch (type) {
      case 'simpanan_setoran':
        return 'Setor ke rekening simpanan';
      case 'simpanan_penarikan':
        return 'Tarik dana dari simpanan';
      case 'pinjaman_pencairan':
        return 'Pinjaman berhasil dicairkan';
      case 'pinjaman_pembayaran':
        return 'Pembayaran cicilan pinjaman';
      default:
        return 'Transaksi keuangan';
    }
  }

  final typeColor = getTypeColor();
  final typeIcon = getTypeIcon();

  return Container(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        // Icon Container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                typeColor,
                typeColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: typeColor.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            typeIcon,
            color: Colors.white,
            size: 24,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Transaction Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity['title'] as String,
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                getActivityDescription(),
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: typeColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: typeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity['date'] as String,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
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
        
        // Amount Column
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              activity['amount'] as String,
              style: TextStyle(
                color: isPositive ? Color(0xFF4CAF50) : Color(0xFFD32F2F),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPositive ? [
                    Color(0xFF4CAF50),
                    Color(0xFF66BB6A),
                  ] : [
                    Color(0xFFD32F2F),
                    Color(0xFFEF5350),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isPositive ? Color(0xFF4CAF50) : Color(0xFFD32F2F))
                        .withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPositive ? 'Masuk' : 'Keluar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4E342E)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E342E),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistentSimpananCard(IconData icon, String title, double saldo, Color color) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 2, color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
            spreadRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Poppins',
                ),
            ),
            const Spacer(),
            Text(
              "Rp ${_formatCurrency(saldo)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Saldo tersedia',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}