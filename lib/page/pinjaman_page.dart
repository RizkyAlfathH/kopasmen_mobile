import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'history_page.dart';
import 'home_page.dart';

class PinjamanPage extends StatefulWidget {
  final String nomorAnggota;
  final String nama;

  const PinjamanPage({
    super.key,
    required this.nomorAnggota,
    this.nama = 'User',
  });

  @override
  State<PinjamanPage> createState() => _PinjamanPageState();
}

class _PinjamanPageState extends State<PinjamanPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> pinjamanList = [];
  bool isLoading = true;
  late TabController _tabController;

  double totalPinjamanReguler = 0;
  double totalPinjamanKhusus = 0;
  double totalPinjamanBarang = 0;
  double totalSisaPinjamanReguler = 0;
  double totalSisaPinjamanKhusus = 0;
  double totalSisaPinjamanBarang = 0;
  double grandTotalPinjaman = 0;
  double grandTotalSisaPinjaman = 0;

  // Warna tema sesuai web
  static const Color kYellowLight = Color(0xFFFFDC16);
  static const Color kYellowMid   = Color(0xFFFFC107);
  static const Color kYellowDark  = Color(0xFFFFB300);
  static const Color kBrown       = Color(0xFF4E342E);
  static const Color kBrownDark   = Color(0xFF3E2723);
  static const Color kWhite       = Colors.white;
  static const Color kBgPage      = Color(0xFFF5F5F5);
  static const Color kTextGrey    = Color(0xFF757575);
  static const Color kBorder      = Color(0xFFE0E0E0);
  static const Color kGreen       = Color(0xFF2E7D32);
  static const Color kRed         = Color(0xFFC62828);
  static const Color kOrange      = Color(0xFFE65100);
  static const Color kBlue        = Color(0xFF1565C0);
  static const Color kPurple      = Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchPinjaman();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchPinjaman() async {
    try {
      final data = await ApiService.getPinjaman(widget.nomorAnggota);
      for (var p in data) {
        try {
          p['angsuran'] = await ApiService.getAngsuran(p['id_pinjaman']);
        } catch (_) {
          p['angsuran'] = [];
        }
      }
      setState(() {
        pinjamanList = data;
        _calculateTotals();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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

  void _calculateTotals() {
    totalPinjamanReguler = 0;
    totalPinjamanKhusus = 0;
    totalPinjamanBarang = 0;
    totalSisaPinjamanReguler = 0;
    totalSisaPinjamanKhusus = 0;
    totalSisaPinjamanBarang = 0;

    for (var item in pinjamanList) {
      final nominal = double.tryParse(
            (item['jumlah_pinjaman'] ?? item['nominal'] ?? "0").toString()) ?? 0;
      final sisaPinjaman = double.tryParse(
            (item['sisa_pinjaman_real'] ?? "0").toString()) ?? 0;
      final status = item['status']?.toString().toLowerCase() ?? '';
      final jenisNama = item['jenis_pinjaman']?['nama_jenis']?.toString().toLowerCase() ?? '';

      if (jenisNama.contains('reguler')) {
        totalPinjamanReguler += nominal;
      } else if (jenisNama.contains('khusus')) {
        totalPinjamanKhusus += nominal;
      } else if (jenisNama.contains('barang')) {
        totalPinjamanBarang += nominal;
      }

      if (status.trim().toLowerCase().contains('aktif') && sisaPinjaman > 0) {
        if (jenisNama.contains('reguler')) {
          totalSisaPinjamanReguler += sisaPinjaman;
        } else if (jenisNama.contains('khusus')) {
          totalSisaPinjamanKhusus += sisaPinjaman;
        } else if (jenisNama.contains('barang')) {
          totalSisaPinjamanBarang += sisaPinjaman;
        }
      }
    }

    grandTotalPinjaman = totalPinjamanReguler + totalPinjamanKhusus + totalPinjamanBarang;
    grandTotalSisaPinjaman = totalSisaPinjamanReguler + totalSisaPinjamanKhusus + totalSisaPinjamanBarang;
  }

  List<dynamic> _getFilteredPinjaman(String type) {
    return pinjamanList.where((item) {
      final jenisNama = item['jenis_pinjaman']?['nama_jenis']?.toString().toLowerCase() ?? '';
      switch (type.toLowerCase()) {
        case 'reguler':
          return jenisNama.contains('reguler') || jenisNama.contains('biasa') ||
              (!jenisNama.contains('khusus') &&
                  !jenisNama.contains('darurat') &&
                  !jenisNama.contains('barang') &&
                  !jenisNama.contains('elektronik'));
        case 'khusus':
          return jenisNama.contains('khusus') || jenisNama.contains('darurat');
        case 'barang':
          return jenisNama.contains('barang') || jenisNama.contains('elektronik');
        default:
          return false;
      }
    }).toList();
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'reguler': return Icons.credit_card;
      case 'khusus':  return Icons.priority_high;
      case 'barang':  return Icons.shopping_cart;
      default:        return Icons.account_balance_wallet;
    }
  }

  // Warna per jenis — tetap pakai warna semantik agar progress bar bermakna
  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'reguler': return kBlue;
      case 'khusus':  return kRed;
      case 'barang':  return kPurple;
      default:        return kBrown;
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s.contains('belum lunas') || s.contains('pending')) return const Color(0xFFE65100);
    if (s.contains('lunas'))  return kGreen;
    if (s.contains('ditolak') || s.contains('gagal')) return kRed;
    return kTextGrey;
  }

  IconData _getStatusIcon(String status) {
    final s = status.toLowerCase().trim();
    if (s.contains('belum lunas') || s.contains('pending')) return Icons.schedule;
    if (s.contains('lunas'))  return Icons.check_circle;
    if (s.contains('ditolak') || s.contains('gagal')) return Icons.error;
    return Icons.info;
  }

  String _formatCurrency(num value) =>
      NumberFormat.decimalPattern('id').format(value.floor());

  String _getMonthName() {
    const names = [
      'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'
    ];
    return names[DateTime.now().month - 1];
  }

  Map<String, Map<String, dynamic>> _getGroupedPinjaman(String type) {
    final filteredData = _getFilteredPinjaman(type);
    Map<String, Map<String, dynamic>> grouped = {};

    for (var p in filteredData) {
      final jenisNama = p['jenis_pinjaman']?['nama_jenis']?.toString() ?? "Tidak diketahui";
      if (grouped.containsKey(jenisNama)) {
        final ex = grouped[jenisNama]!;
        ex['count'] = (ex['count'] as int) + 1;
        ex['total_nominal'] = (ex['total_nominal'] as double) +
            (double.tryParse((p['jumlah_pinjaman'] ?? p['nominal'] ?? "0").toString()) ?? 0);
        ex['total_sisa'] = (ex['total_sisa'] as double) +
            (double.tryParse((p['sisa_pinjaman_real'] ?? "0").toString()) ?? 0);
        ex['total_angsuran'] = (ex['total_angsuran'] as double) +
            ((double.tryParse(p['angsuran_per_bulan'].toString()) ?? 0) +
             (double.tryParse(p['jasa_rupiah'].toString()) ?? 0));
        (ex['details'] as List).add(p);
      } else {
        grouped[jenisNama] = {
          'jenis_nama': jenisNama,
          'count': 1,
          'total_nominal': double.tryParse((p['jumlah_pinjaman'] ?? p['nominal'] ?? "0").toString()) ?? 0,
          'total_sisa': double.tryParse(p['sisa_pinjaman_real'].toString()) ?? 0,
          'total_angsuran': (double.tryParse(p['angsuran_per_bulan'].toString()) ?? 0) +
                            (double.tryParse(p['jasa_rupiah'].toString()) ?? 0),
          'details': [p],
          'status': p['status']?.toString() ?? "-",
        };
      }
    }
    return grouped;
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

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
                      'Memuat data pinjaman...',
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
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 480.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: kYellowLight,
                    elevation: 0,
                    leading: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomePage(
                            user: {
                              'No Anggota': widget.nomorAnggota,
                              'nama': widget.nama,
                            },
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: kBrownDark,
                          size: 18,
                        ),
                      ),
                    ),
                    title: const Text(
                      'Pinjaman',
                      style: TextStyle(
                        color: kBrownDark,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [kYellowLight, kYellowMid, kYellowDark],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                            child: Column(
                              children: [
                                // User info card
                                _buildUserInfoCard(),
                                const SizedBox(height: 16),
                                // Summary cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total Pinjaman',
                                        grandTotalPinjaman,
                                        Icons.trending_up,
                                        kBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Sisa Tagihan',
                                        grandTotalSisaPinjaman,
                                        Icons.pending_actions,
                                        kOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Status card
                                _buildStatusCard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  // Tab bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card, size: 16),
                              SizedBox(width: 6),
                              Text('Reguler'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.priority_high, size: 16),
                              SizedBox(width: 6),
                              Text('Khusus'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart, size: 16),
                              SizedBox(width: 6),
                              Text('Barang'),
                            ],
                          ),
                        ),
                      ],
                      labelColor: kBrownDark,
                      unselectedLabelColor: kBrown.withOpacity(0.4),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                      indicator: BoxDecoration(
                        color: kYellowLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                    ),
                  ),

                  Flexible(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent('reguler'),
                        _buildTabContent('khusus'),
                        _buildTabContent('barang'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // User info card di dalam header
  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: kYellowLight,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.person, color: kBrownDark, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nama,
                  style: const TextStyle(
                    color: kBrownDark,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kYellowLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kYellowLight, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, size: 12, color: kBrown),
                      const SizedBox(width: 4),
                      Text(
                        'No. Anggota: ${widget.nomorAnggota}',
                        style: const TextStyle(
                          color: kBrown,
                          fontSize: 11,
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
        ],
      ),
    );
  }

  // Summary card (total pinjaman / sisa tagihan)
  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: kTextGrey,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Rp ${_formatCurrency(amount)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Status keuangan card
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kYellowLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet, color: kBrownDark, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Keuangan',
                  style: TextStyle(
                    color: kBrown,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  grandTotalSisaPinjaman > 0
                      ? 'Masih Ada Tanggungan'
                      : pinjamanList.isEmpty
                          ? 'Belum Ada Pinjaman'
                          : 'Semua Pinjaman Lunas',
                  style: TextStyle(
                    color: grandTotalSisaPinjaman > 0
                        ? kOrange
                        : pinjamanList.isEmpty
                            ? kTextGrey
                            : kGreen,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (grandTotalSisaPinjaman > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kOrange.withOpacity(0.3)),
              ),
              child: Text(
                '${pinjamanList.where((p) => (double.tryParse(p['sisa_pinjaman_real'].toString()) ?? 0) > 0).length} aktif',
                style: const TextStyle(
                  color: kOrange,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── TAB CONTENT ─────────────────────────────────────────────────────────

  Widget _buildTabContent(String type) {
    final filteredData = _getFilteredPinjaman(type);
    final groupedLoans = _getGroupedPinjaman(type);
    final totalPinjaman = type == 'reguler'
        ? totalPinjamanReguler
        : type == 'khusus'
            ? totalPinjamanKhusus
            : totalPinjamanBarang;
    final totalSisaPinjaman = type == 'reguler'
        ? totalSisaPinjamanReguler
        : type == 'khusus'
            ? totalSisaPinjamanKhusus
            : totalSisaPinjamanBarang;

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kYellowLight.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kYellowLight, width: 1.5),
              ),
              child: Icon(
                _getIconForType(type),
                size: 44,
                color: kBrown,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada pinjaman $type',
              style: const TextStyle(
                color: kBrown,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Data akan muncul setelah Anda mengajukan pinjaman $type',
              style: TextStyle(
                color: kBrown.withOpacity(0.5),
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    double totalTagihanBulanan = 0;
    for (var g in groupedLoans.values) {
      totalTagihanBulanan += g['total_angsuran'] as double;
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary card per tab — border warna tipis, putih bersih
                _buildTabSummaryCard(type, totalPinjaman, totalSisaPinjaman, totalTagihanBulanan, groupedLoans),
                const SizedBox(height: 20),
                // List header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kYellowLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getIconForType(type), size: 16, color: kBrown),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ringkasan Pinjaman',
                      style: TextStyle(
                        color: kBrown,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kYellowLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kYellowLight, width: 1),
                      ),
                      child: Text(
                        '${groupedLoans.length} grup',
                        style: const TextStyle(
                          color: kBrown,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Lihat detail link
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryPage(
                          nomorAnggota: widget.nomorAnggota,
                          nama: widget.nama,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat detail transaksi',
                            style: TextStyle(
                              color: _getColorForType(type),
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              color: _getColorForType(type), size: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loan group cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final groupList = groupedLoans.values.toList();
                final group = groupList[index];
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index == groupList.length - 1 ? 30 : 12),
                  child: _buildGroupCard(type, group),
                );
              },
              childCount: groupedLoans.length,
            ),
          ),
        ),
      ],
    );
  }

  // Summary card per tab
  Widget _buildTabSummaryCard(
    String type,
    double totalPinjaman,
    double totalSisaPinjaman,
    double totalTagihanBulanan,
    Map<String, Map<String, dynamic>> groupedLoans,
  ) {
    final color = _getColorForType(type);
    return Container(
      width: double.infinity,
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIconForType(type), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pinjaman ${type[0].toUpperCase()}${type.substring(1)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total yang telah dipinjam',
                      style: TextStyle(
                        color: kBrown.withOpacity(0.5),
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: color.withOpacity(0.15), thickness: 1),
          const SizedBox(height: 12),

          // Total & sisa
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pinjaman',
                        style: const TextStyle(
                            color: kTextGrey,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(totalPinjaman)}',
                      style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: color.withOpacity(0.2)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Sisa Tagihan',
                        style: TextStyle(
                            color: kTextGrey,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(totalSisaPinjaman)}',
                      style: TextStyle(
                          color: totalSisaPinjaman > 0 ? kRed : kGreen,
                          fontSize: 17,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tagihan bulanan
          if (totalSisaPinjaman > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kOrange.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: kOrange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tagihan Bulan Ini (${_getMonthName()}):',
                    style: const TextStyle(
                        color: kTextGrey,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Rp ${_formatCurrency(totalTagihanBulanan)}',
                    style: const TextStyle(
                        color: kOrange,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            '${groupedLoans.length} jenis pinjaman (${_getFilteredPinjaman(type).length} total transaksi)',
            style: TextStyle(
                color: kBrown.withOpacity(0.5),
                fontSize: 12,
                fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  // Group card per jenis pinjaman
  Widget _buildGroupCard(String type, Map<String, dynamic> group) {
    final jenisNama       = group['jenis_nama'] as String;
    final count           = group['count'] as int;
    final totalNominal    = group['total_nominal'] as double;
    final totalSisa       = group['total_sisa'] as double;
    final totalAngsuran   = group['total_angsuran'] as double;
    final details         = group['details'] as List;
    final overallStatus   = totalSisa > 0 ? "Belum Lunas" : "Lunas";
    final progress        = totalNominal > 0
        ? ((totalNominal - totalSisa) / totalNominal).clamp(0.0, 1.0)
        : 0.0;
    final color           = _getColorForType(type);

    // Riwayat angsuran
    List<Map<String, dynamic>> allPayments = [];
    for (var loan in details) {
      final cicilan  = loan['cicilan_terbayar'] ?? 0;
      final angsuran = (loan['angsuran_per_bulan'] is num)
          ? (loan['angsuran_per_bulan'] as num).toDouble()
          : double.tryParse(loan['angsuran_per_bulan']?.toString() ?? '') ?? 0.0;
      DateTime startDate = DateTime.parse(loan['tanggal_meminjam']);
      for (int i = 0; i < cicilan; i++) {
        allPayments.add({
          'tanggal_pembayaran': startDate.add(Duration(days: 30 * (i + 1))).toIso8601String(),
          'nominal': angsuran,
        });
      }
    }
    allPayments.sort((a, b) => DateTime.parse(b['tanggal_pembayaran'])
        .compareTo(DateTime.parse(a['tanggal_pembayaran'])));
    final latestPayments = allPayments.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIconForType(type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jenisNama,
                      style: const TextStyle(
                        color: kBrown,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count Pinjaman Tergabung',
                      style: const TextStyle(
                        color: kTextGrey,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(overallStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _getStatusColor(overallStatus).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(overallStatus),
                        size: 11, color: _getStatusColor(overallStatus)),
                    const SizedBox(width: 4),
                    Text(
                      overallStatus,
                      style: TextStyle(
                        color: _getStatusColor(overallStatus),
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: kBorder, thickness: 1),
          const SizedBox(height: 10),

          // Total & sisa
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.trending_up, size: 14, color: kBlue),
                      const SizedBox(width: 4),
                      const Text('Total Pinjaman',
                          style: TextStyle(
                              color: kTextGrey,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(totalNominal)}',
                      style: const TextStyle(
                          color: kBlue,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: kBorder),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.pending_actions,
                            size: 14,
                            color: totalSisa > 0 ? kRed : kGreen),
                        const SizedBox(width: 4),
                        const Text('Sisa Tagihan',
                            style: TextStyle(
                                color: kTextGrey,
                                fontSize: 11,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(totalSisa)}',
                      style: TextStyle(
                          color: totalSisa > 0 ? kRed : kGreen,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar & tagihan bulanan
          if (totalSisa > 0) ...[
            const SizedBox(height: 14),
            // Tagihan bulan ini
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kOrange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: kOrange, size: 14),
                  const SizedBox(width: 8),
                  const Text(
                    'Tagihan Bulan Ini: ',
                    style: TextStyle(
                        color: kTextGrey,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Rp ${_formatCurrency(totalAngsuran)}',
                    style: const TextStyle(
                        color: kOrange,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress Pembayaran',
                    style: TextStyle(
                        color: kTextGrey,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGreen.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: kGreen, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'SEMUA PINJAMAN LUNAS',
                    style: TextStyle(
                      color: kGreen,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Riwayat pembayaran
          if (totalSisa > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBgPage,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          color: kBrown, size: 15),
                      const SizedBox(width: 6),
                      const Text(
                        'Riwayat Pembayaran',
                        style: TextStyle(
                          color: kBrown,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kYellowLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kYellowLight, width: 1),
                        ),
                        child: Text(
                          '${allPayments.length} transaksi',
                          style: const TextStyle(
                            color: kBrown,
                            fontSize: 10,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (latestPayments.isEmpty)
                    const Text(
                      'Belum ada pembayaran',
                      style: TextStyle(
                          color: kTextGrey,
                          fontSize: 12,
                          fontFamily: 'Poppins'),
                    )
                  else
                    ...latestPayments.map((pay) {
                      final tgl = DateFormat('dd MMM yyyy').format(
                          DateTime.parse(pay['tanggal_pembayaran']));
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 12, color: kTextGrey),
                                const SizedBox(width: 4),
                                Text(
                                  tgl,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: kTextGrey,
                                      fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                            Text(
                              'Rp ${_formatCurrency(pay['nominal'])}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kGreen,
                                  fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}