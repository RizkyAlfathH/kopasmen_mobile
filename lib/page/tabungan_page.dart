import 'package:flutter/material.dart';
import 'package:Kopasmen_Mobile/page/history_page.dart';
import 'package:Kopasmen_Mobile/page/home_page.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class TabunganPage extends StatefulWidget {
  final String nomorAnggota;
  final String nama;

  const TabunganPage({
    super.key,
    required this.nomorAnggota,
    this.nama = 'User',
  });

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _simpanan = [];
  List<dynamic> _penarikan = [];
  bool _loading = true;
  late TabController _tabController;

  double _simpananPokok = 0;
  double _simpananWajib = 0;
  double _simpananSukarela = 0;
  double _totalSimpanan = 0;

  double _penarikanPokok = 0;
  double _penarikanWajib = 0;
  double _penarikanSukarela = 0;
  double _totalPenarikan = 0;

  // ─── Warna tema (konsisten dengan PinjamanPage) ───────────────────────────
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
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    try {
      final results = await Future.wait([
        ApiService.getSimpanan(widget.nomorAnggota),
        ApiService.getPenarikan(widget.nomorAnggota),
      ]);
      setState(() {
        _simpanan  = results[0];
        _penarikan = results[1];
        _calculateTotals();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
    double pokok = 0, wajib = 0, sukarela = 0;
    double tPokok = 0, tWajib = 0, tSukarela = 0;

    for (var item in _simpanan) {
      final nominal  = double.tryParse(item['nominal'].toString()) ?? 0;
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString().toLowerCase();
      if (jenisNama.contains('pokok'))    pokok    += nominal;
      else if (jenisNama.contains('wajib'))   wajib    += nominal;
      else if (jenisNama.contains('sukarela')) sukarela += nominal;
    }

    for (var item in _penarikan) {
      final nominal  = double.tryParse(item['nominal'].toString()) ?? 0;
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString().toLowerCase();
      if (jenisNama.contains('pokok'))    { tPokok    += nominal; pokok    -= nominal; }
      else if (jenisNama.contains('wajib'))   { tWajib    += nominal; wajib    -= nominal; }
      else if (jenisNama.contains('sukarela')) { tSukarela += nominal; sukarela -= nominal; }
    }

    _simpananPokok    = pokok    < 0 ? 0 : pokok;
    _simpananWajib    = wajib    < 0 ? 0 : wajib;
    _simpananSukarela = sukarela < 0 ? 0 : sukarela;
    _totalSimpanan    = _simpananPokok + _simpananWajib + _simpananSukarela;

    _penarikanPokok    = tPokok;
    _penarikanWajib    = tWajib;
    _penarikanSukarela = tSukarela;
    _totalPenarikan    = tPokok + tWajib + tSukarela;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pokok':    return Icons.account_balance;
      case 'wajib':    return Icons.savings;
      case 'sukarela': return Icons.volunteer_activism;
      default:         return Icons.account_balance_wallet;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'pokok':    return kGreen;
      case 'wajib':    return kBlue;
      case 'sukarela': return kPurple;
      default:         return kBrown;
    }
  }

  double _getSaldoForType(String type) {
    switch (type.toLowerCase()) {
      case 'pokok':    return _simpananPokok;
      case 'wajib':    return _simpananWajib;
      case 'sukarela': return _simpananSukarela;
      default:         return 0;
    }
  }

  double _getPenarikanForType(String type) {
    switch (type.toLowerCase()) {
      case 'pokok':    return _penarikanPokok;
      case 'wajib':    return _penarikanWajib;
      case 'sukarela': return _penarikanSukarela;
      default:         return 0;
    }
  }

  double _getGrossSetoran(String type) {
    // Gross setoran = saldo bersih + penarikan
    return _getSaldoForType(type) + _getPenarikanForType(type);
  }

  List<Map<String, dynamic>> _getCombinedTransactions(String type) {
    List<Map<String, dynamic>> combined = [];

    for (var item in _simpanan) {
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString().toLowerCase();
      if (jenisNama.contains(type)) {
        combined.add({
          'type': 'simpanan',
          'data': item,
          'date_field': 'tanggal',
          'nominal': double.tryParse(item['nominal'].toString()) ?? 0,
          'is_positive': true,
          'title': 'Setoran Simpanan ${type[0].toUpperCase()}${type.substring(1)}',
        });
      }
    }

    for (var item in _penarikan) {
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString().toLowerCase();
      if (jenisNama.contains(type)) {
        combined.add({
          'type': 'penarikan',
          'data': item,
          'date_field': 'tanggal_penarikan',
          'nominal': double.tryParse(item['nominal'].toString()) ?? 0,
          'is_positive': false,
          'title': 'Penarikan Simpanan ${type[0].toUpperCase()}${type.substring(1)}',
        });
      }
    }

    combined.sort((a, b) {
      DateTime parseDate(String s) {
        try {
          if (s.contains('T')) return DateTime.parse(s);
          if (s.contains('-') && s.length >= 10) return DateTime.parse(s.substring(0, 10));
          if (s.contains('/')) {
            final p = s.split('/');
            if (p.length == 3) return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
          }
          return DateTime(1900);
        } catch (_) { return DateTime(1900); }
      }
      final da = parseDate(a['data'][a['date_field']].toString());
      final db = parseDate(b['data'][b['date_field']].toString());
      return db.compareTo(da);
    });

    return combined;
  }

  String _formatCurrency(num value) =>
      NumberFormat.decimalPattern('id').format(value.floor());

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      body: _loading
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
                      'Memuat data simpanan...',
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
                              'Nomor Anggota': widget.nomorAnggota,
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
                      'Simpanan',
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
                                _buildUserInfoCard(),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total Simpanan',
                                        _totalSimpanan,
                                        Icons.savings,
                                        kGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total Penarikan',
                                        _totalPenarikan,
                                        Icons.money_off,
                                        kOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
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
                              Icon(Icons.account_balance, size: 16),
                              SizedBox(width: 6),
                              Text('Pokok'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.savings, size: 16),
                              SizedBox(width: 6),
                              Text('Wajib'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.volunteer_activism, size: 16),
                              SizedBox(width: 6),
                              Text('Sukarela'),
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
                        _buildTabContent('pokok'),
                        _buildTabContent('wajib'),
                        _buildTabContent('sukarela'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Header widgets ───────────────────────────────────────────────────────

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

  Widget _buildStatusCard() {
    final hasSimpanan = _totalSimpanan > 0;
    final hasData     = _simpanan.isNotEmpty;

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
                  'Status Simpanan',
                  style: TextStyle(
                    color: kBrown,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  !hasData
                      ? 'Belum Ada Simpanan'
                      : hasSimpanan
                          ? 'Simpanan Aktif'
                          : 'Saldo Nihil',
                  style: TextStyle(
                    color: !hasData
                        ? kTextGrey
                        : hasSimpanan
                            ? kGreen
                            : kOrange,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (hasSimpanan)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGreen.withOpacity(0.3)),
              ),
              child: Text(
                '${_simpanan.length} transaksi',
                style: const TextStyle(
                  color: kGreen,
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

  // ─── Tab content ──────────────────────────────────────────────────────────

  Widget _buildTabContent(String type) {
    final allTransactions = _getCombinedTransactions(type);
    final saldo           = _getSaldoForType(type);
    final penarikan       = _getPenarikanForType(type);
    final grossSetoran    = _getGrossSetoran(type);

    if (allTransactions.isEmpty) {
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
              child: Icon(_getIconForType(type), size: 44, color: kBrown),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada simpanan $type',
              style: const TextStyle(
                color: kBrown,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Data akan muncul setelah ada transaksi simpanan $type',
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

    final latest3 = allTransactions.take(3).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary card per tab
                _buildTabSummaryCard(type, grossSetoran, saldo, penarikan, allTransactions.length),
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
                      'Transaksi Terbaru',
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
                        '3 terbaru',
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

                // Lihat semua link
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
                            'Lihat semua transaksi',
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

        // Transaction cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tx         = latest3[index];
                final item       = tx['data'] as Map;
                final amount     = tx['nominal'] as double;
                final isPositive = tx['is_positive'] as bool;
                final dateField  = tx['date_field'] as String;
                final color      = _getColorForType(type);

                String dateStr = '-';
                try {
                  final raw = item[dateField]?.toString() ?? '';
                  if (raw.isNotEmpty) {
                    dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
                  }
                } catch (_) {}

                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index == latest3.length - 1 ? 30 : 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        // Leading icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isPositive
                                ? color.withOpacity(0.12)
                                : kRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isPositive ? _getIconForType(type) : Icons.money_off,
                            color: isPositive ? color : kRed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title + date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx['title'] as String,
                                style: const TextStyle(
                                  color: kBrownDark,
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 12, color: kTextGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      color: kTextGrey,
                                      fontSize: 11,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Amount + badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isPositive ? '+' : '-'} Rp ${_formatCurrency(amount)}',
                              style: TextStyle(
                                color: isPositive ? color : kRed,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? kGreen.withOpacity(0.1)
                                    : kOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPositive
                                      ? kGreen.withOpacity(0.4)
                                      : kOrange.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                isPositive ? 'Masuk' : 'Keluar',
                                style: TextStyle(
                                  color: isPositive ? kGreen : kOrange,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: latest3.length,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Tab summary card (mirip _buildTabSummaryCard di PinjamanPage) ────────

  Widget _buildTabSummaryCard(
    String type,
    double grossSetoran,
    double saldo,
    double penarikan,
    int totalTransaksi,
  ) {
    final color    = _getColorForType(type);
    final progress = grossSetoran > 0
        ? (saldo / grossSetoran).clamp(0.0, 1.0)
        : 0.0;

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
                      'Simpanan ${type[0].toUpperCase()}${type.substring(1)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Saldo setelah penarikan',
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

          // Setoran & saldo bersih
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Setoran',
                        style: TextStyle(
                            color: kTextGrey,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(grossSetoran)}',
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
                    const Text('Saldo Bersih',
                        style: TextStyle(
                            color: kTextGrey,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(saldo)}',
                      style: TextStyle(
                          color: saldo > 0 ? kGreen : kTextGrey,
                          fontSize: 17,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Penarikan info
          if (penarikan > 0) ...[
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
                  const Icon(Icons.money_off, color: kOrange, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Total Penarikan: ',
                    style: TextStyle(
                        color: kTextGrey,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Rp ${_formatCurrency(penarikan)}',
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

          const SizedBox(height: 12),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rasio Saldo',
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

          const SizedBox(height: 10),
          Text(
            '$totalTransaksi total transaksi',
            style: TextStyle(
                color: kBrown.withOpacity(0.5),
                fontSize: 12,
                fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}