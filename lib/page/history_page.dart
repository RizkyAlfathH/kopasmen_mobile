import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';

class HistoryPage extends StatefulWidget {
  final String nomorAnggota;
  final String nama;

  const HistoryPage({
    super.key,
    required this.nomorAnggota,
    this.nama = 'User',
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int selectedTab = 0;
  bool isLoading = false;
  List<TransactionItem> transactions = [];
  String searchQuery = '';

  final List<String> tabs = ['Simpanan', 'Pinjaman'];

  List<dynamic> _simpananData = [];
  List<dynamic> _penarikanData = [];
  List<dynamic> _pinjamanData = [];

  // Warna tema sesuai web
  static const Color kYellowLight = Color(0xFFFFDC16);
  static const Color kYellowMid   = Color(0xFFFFC107);
  static const Color kYellowDark  = Color(0xFFFFB300);
  static const Color kBrown       = Color(0xFF4E342E);
  static const Color kBrownDark   = Color(0xFF3E2723);
  static const Color kBrownMid    = Color(0xFF6D4C41);
  static const Color kBrownLight  = Color(0xFF8D6E63);
  static const Color kWhite       = Colors.white;
  static const Color kBgPage      = Color(0xFFF5F5F5);
  static const Color kBorder      = Color(0xFFE0E0E0);
  static const Color kTextGrey    = Color(0xFF6B6B6B);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _fetchSimpananData(),
        _fetchPenarikanData(),
        _fetchPinjamanData(),
      ]);
      _processTransactionData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: kBrownDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchSimpananData() async {
    try {
      _simpananData = await ApiService.getSimpanan(widget.nomorAnggota);
    } catch (e) {
      _simpananData = [];
    }
  }

  Future<void> _fetchPenarikanData() async {
    try {
      _penarikanData = await ApiService.getPenarikan(widget.nomorAnggota);
    } catch (e) {
      _penarikanData = [];
    }
  }

  Future<void> _fetchPinjamanData() async {
    try {
      _pinjamanData = await ApiService.getPinjaman(widget.nomorAnggota);
    } catch (e) {
      _pinjamanData = [];
    }
  }

  void _processTransactionData() {
    List<TransactionItem> processedTransactions = [];

    // Simpanan
    for (var item in _simpananData) {
      final amount   = double.tryParse(item['nominal'].toString()) ?? 0;
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString();
      final tanggal  = item['tanggal_meminjam'].toString();
      processedTransactions.add(TransactionItem(
        id: '${widget.nomorAnggota}simpanan${item['id']}',
        title: jenisNama,
        description: 'Setoran $jenisNama - ${widget.nama}',
        amount: '+ Rp ${_formatCurrency(amount)}',
        date: _formatDate(tanggal),
        time: _extractTime(tanggal),
        isPositive: true,
        type: 'simpanan',
        userNip: widget.nomorAnggota,
        rawData: item,
      ));
    }

    // Penarikan
    for (var item in _penarikanData) {
      final amount    = double.tryParse(item['nominal'].toString()) ?? 0;
      final tanggal   = item['tanggal'].toString();
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString();
      processedTransactions.add(TransactionItem(
        id: '${widget.nomorAnggota}penarikan${item['id']}',
        title: 'Penarikan $jenisNama',
        description: 'Penarikan $jenisNama - ${widget.nama}',
        amount: '- Rp ${_formatCurrency(amount)}',
        date: _formatDate(tanggal),
        time: _extractTime(tanggal),
        isPositive: false,
        type: 'simpanan',
        userNip: widget.nomorAnggota,
        rawData: item,
      ));
    }

    // Pinjaman
    for (var item in _pinjamanData) {
      final amount    = double.tryParse(item['jumlah_pinjaman'].toString()) ?? 0;
      final jenisNama = item['jenis_pinjaman']?['nama_jenis']?.toString() ?? 'Pinjaman';
      final tanggal   = item['tanggal'].toString();
      processedTransactions.add(TransactionItem(
        id: '${widget.nomorAnggota}pinjaman${item['id_pinjaman']}',
        title: 'Riwayat Pinjaman $jenisNama',
        description: 'Pinjaman $jenisNama - ${widget.nama}',
        amount: 'Rp ${_formatCurrency(amount)}',
        date: _formatDate(tanggal),
        time: _extractTime(tanggal),
        isPositive: true,
        type: 'pinjaman',
        userNip: widget.nomorAnggota,
        rawData: item,
      ));

      if (item['angsuran'] != null && item['angsuran'] is List) {
        for (var angsuran in item['angsuran'] as List) {
          final angsuranAmount  = double.tryParse(angsuran['nominal'].toString()) ?? 0;
          final angsuranTanggal = angsuran['tanggal_bayar'].toString();
          processedTransactions.add(TransactionItem(
            id: '${widget.nomorAnggota}angsuran${angsuran['id_pembayaran']}',
            title: 'Pembayaran Angsuran $jenisNama',
            description: 'Cicilan $jenisNama - ${widget.nama}',
            amount: 'Rp ${_formatCurrency(angsuranAmount)}',
            date: _formatDate(angsuranTanggal),
            time: _extractTime(angsuranTanggal),
            isPositive: false,
            type: 'pinjaman',
            userNip: widget.nomorAnggota,
            rawData: angsuran,
          ));
        }
      }
    }

    // Sort terbaru
    processedTransactions.sort((a, b) {
      try {
        final dateA = DateTime.parse(
          a.rawData['tanggal_bayar']?.toString() ??
          a.rawData['tanggal']?.toString() ??
          DateTime.now().toString(),
        );
        final dateB = DateTime.parse(
          b.rawData['tanggal_bayar']?.toString() ??
          b.rawData['tanggal']?.toString() ??
          DateTime.now().toString(),
        );
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    setState(() => transactions = processedTransactions);
  }

  List<TransactionItem> get filteredTransactions {
    List<TransactionItem> filtered = transactions
        .where((t) => t.type == tabs[selectedTab].toLowerCase())
        .toList();

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q) ||
        t.date.toLowerCase().contains(q),
      ).toList();
    }

    if (filtered.length > 5) filtered = filtered.sublist(0, 5);
    return filtered;
  }

  String _formatCurrency(double amount) =>
      NumberFormat.decimalPattern('id').format(amount);

  String _formatDate(String dateString) {
    try {
      return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(dateString));
    } catch (_) {
      return dateString;
    }
  }

  String _extractTime(String dateString) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(dateString));
    } catch (_) {
      return '00:00';
    }
  }

  Future<void> _refreshTransactions() async => _loadTransactions();

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: kBrown,
              onRefresh: _refreshTransactions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildUserInfo(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildTabs(),
                    const SizedBox(height: 16),
                    _buildTransactionContent(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header — kuning gradient + teks coklat gelap, persis seperti web
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kYellowLight, kYellowMid, kYellowDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Tombol back
              GestureDetector(
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
                  padding: const EdgeInsets.all(8),
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
              const SizedBox(width: 14),

              // Judul
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Transaksi',
                      style: TextStyle(
                        color: kBrownDark,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Detail aktivitas keuangan Anda',
                      style: TextStyle(
                        color: kBrown.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Icon kanan
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history, color: kBrownDark, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // User info card — border kuning, background kuning transparan
  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kYellowLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kYellowLight, width: 1.2),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: kYellowLight,
            child: Text(
              widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: kBrownDark,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nama & No Anggota
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nama,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: kBrown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No. Anggota: ${widget.nomorAnggota}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: kTextGrey,
                  ),
                ),
              ],
            ),
          ),

          // Badge jumlah transaksi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kYellowLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${filteredTransactions.length} Transaksi',
              style: const TextStyle(
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

  // Search bar — putih bersih, border abu tipis
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v),
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Poppins',
          color: kBrown,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Cari transaksi (judul / tanggal)...',
          hintStyle: TextStyle(
            color: kBrown.withOpacity(0.4),
            fontSize: 13,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(Icons.search, color: kBrownLight, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // Tab Simpanan / Pinjaman — underline kuning aktif
  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder, width: 1)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      tabs[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive ? kBrownDark : kBrown.withOpacity(0.5),
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive ? kYellowLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // Konten transaksi
  Widget _buildTransactionContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kYellowMid),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Memuat riwayat transaksi...',
                style: TextStyle(
                  color: kTextGrey,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = filteredTransactions;
    if (list.isEmpty) return _buildEmptyState();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildTransactionCard(list[i]),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kYellowLight.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kYellowLight, width: 1.5),
              ),
              child: const Icon(Icons.history, size: 48, color: kBrown),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada transaksi ${tabs[selectedTab].toLowerCase()}',
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: kBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'untuk ${widget.nama}',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: kTextGrey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshTransactions,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Muat Ulang',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kYellowLight,
                foregroundColor: kBrownDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Transaction card — putih bersih, icon kuning, teks coklat
  Widget _buildTransactionCard(TransactionItem transaction) {
    final isPinjaman = transaction.type == 'pinjaman';
    final amountColor = isPinjaman
        ? kBrown
        : (transaction.isPositive
            ? const Color(0xFF2E7D32)   // hijau gelap untuk masuk
            : const Color(0xFFC62828)); // merah gelap untuk keluar

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container — kuning dengan icon coklat
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kYellowLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPinjaman ? Icons.credit_card : Icons.account_balance_wallet,
              color: kBrownDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Info transaksi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: kBrown,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: kBrownMid,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: kBrownLight),
                    const SizedBox(width: 4),
                    Text(
                      transaction.date,
                      style: const TextStyle(
                        color: kBrownLight,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (transaction.time != '00:00') ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 12, color: kBrownLight),
                      const SizedBox(width: 4),
                      Text(
                        transaction.time,
                        style: const TextStyle(
                          color: kBrownLight,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Nominal
          Text(
            transaction.amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class TransactionItem {
  final String id;
  final String title;
  final String description;
  final String amount;
  final String date;
  final String time;
  final bool isPositive;
  final String type;
  final String userNip;
  final Map<String, dynamic> rawData;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.time,
    required this.isPositive,
    required this.type,
    required this.userNip,
    required this.rawData,
  });
}