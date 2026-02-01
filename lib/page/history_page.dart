import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';

void main() {
  runApp(const HistoryApp());
}

class HistoryApp extends StatelessWidget {
  const HistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      home: const HistoryPage(
        nip: "123456789",
        nama: "John Doe",
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  final String nip;
  final String nama;

  const HistoryPage({
    super.key,
    required this.nip,
    required this.nama,
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

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _fetchSimpananData(),
        _fetchPenarikanData(),
        _fetchPinjamanData(),
      ]);
      _processTransactionData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transactions: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSimpananData() async {
    try {
      _simpananData = await ApiService.getSimpanan(widget.nip);
    } catch (e) {
      print('Error fetching simpanan: $e');
      _simpananData = [];
    }
  }

  Future<void> _fetchPinjamanData() async {
    try {
      _pinjamanData = await ApiService.getPinjaman(widget.nip);
    } catch (e) {
      print('Error fetching pinjaman: $e');
      _pinjamanData = [];
    }
  }

  Future<void> _fetchPenarikanData() async {
    try {
      _penarikanData = await ApiService.getPenarikan(widget.nip);
    } catch (e) {
      print('Error fetching penarikan: $e');
      _penarikanData = [];
    }
  }

  void _processTransactionData() {
    List<TransactionItem> processedTransactions = [];

    // Simpanan
    for (var item in _simpananData) {
      final amount = double.tryParse(item['nominal'].toString()) ?? 0;
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString();
      final tanggal = item['tanggal_menyimpan'].toString();

      processedTransactions.add(TransactionItem(
        id: '${widget.nip}simpanan${item['id']}',
        title: jenisNama,
        description: 'Setoran $jenisNama - ${widget.nama}',
        amount: '+ Rp ${_formatCurrency(amount)}',
        date: _formatDate(tanggal),
        time: _extractTime(tanggal),
        isPositive: true,
        type: 'simpanan',
        userNip: widget.nip,
        rawData: item,
      ));
    }

    // Penarikan
    for (var item in _penarikanData) {
      final amount = double.tryParse(item['nominal'].toString()) ?? 0;
      final tanggal = item['tanggal_penarikan'].toString();
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString();

      processedTransactions.add(TransactionItem(
        id: '${widget.nip}penarikan${item['id']}',
        title: 'Penarikan $jenisNama',
        description: 'Penarikan $jenisNama  - ${widget.nama}',
        amount: '- Rp ${_formatCurrency(amount)}',
        date: _formatDate(tanggal),
        time: _extractTime(tanggal),
        isPositive: false,
        type: 'simpanan',
        userNip: widget.nip,
        rawData: item,
      ));
    }

    // Pinjaman
    for (var item in _pinjamanData) {
      final amount = double.tryParse(item['jumlah_pinjaman'].toString()) ?? 0;
      final jenisNama = item['jenis_pinjaman']?['nama_jenis']?.toString() ?? 'Pinjaman';
      final tanggal = item['tanggal_meminjam'].toString();

      // Pencairan pinjaman
      processedTransactions.add(TransactionItem(
        id: '${widget.nip}pinjaman${item['id_pinjaman']}',
        title: 'Riwayat Pinjaman $jenisNama',
        description: 'Pinjaman $jenisNama - ${widget.nama}',
        amount: 'Rp ${_formatCurrency(amount)}',
        date: _formatDate(tanggal),
        time: _extractTime(tanggal),
        isPositive: true, 
        type: 'pinjaman',
        userNip: widget.nip,
        rawData: item,
      ));

      processedTransactions.add(TransactionItem(
        id: '${widget.nip}pinjaman${item['id_pinjaman']}',
        title: 'Pembayaran $jenisNama',
        description: 'Pinjaman $jenisNama - ${widget.nama}',
        amount: 'Rp ${_formatCurrency(amount)}',
        date: _formatDate(tanggal),
        time: _extractTime(tanggal),
        isPositive: true,
        type: 'pinjaman',
        userNip: widget.nip,
        rawData: item,
      ));

      // Riwayat angsuran (pembayaran cicilan)
      if (item['angsuran'] != null && item['angsuran'] is List) {
        List<dynamic> angsuranList = item['angsuran'];
        for (var angsuran in angsuranList) {
          final angsuranAmount = double.tryParse(angsuran['nominal'].toString()) ?? 0;
          final angsuranTanggal = angsuran['tanggal_bayar'].toString();

          processedTransactions.add(TransactionItem(
            id: '${widget.nip}angsuran${angsuran['id']}',
            title: 'Pembayaran Angsuran $jenisNama',
            description: 'Cicilan $jenisNama - ${widget.nama}',
            amount: 'Rp ${_formatCurrency(angsuranAmount)}', // tanpa minus
            date: _formatDate(angsuranTanggal),
            time: _extractTime(angsuranTanggal),
            isPositive: false, // abaikan, styling nanti di card
            type: 'pinjaman',
            userNip: widget.nip,
            rawData: angsuran,
          ));
        }
      }
    }

    // Sort by date terbaru
    processedTransactions.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.rawData['tanggal_menyimpan'] ??
            a.rawData['tanggal_meminjam'] ??
            a.rawData['tanggal_bayar'] ??
            DateTime.now().toString());
        final dateB = DateTime.parse(b.rawData['tanggal_menyimpan'] ??
            b.rawData['tanggal_meminjam'] ??
            b.rawData['tanggal_bayar'] ??
            DateTime.now().toString());
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    setState(() {
      transactions = processedTransactions;
    });
  }

  List<TransactionItem> get filteredTransactions {
    List<TransactionItem> filtered = transactions;

    // Tab filter
    final currentTabType = tabs[selectedTab].toLowerCase();
    filtered = filtered.where((transaction) {
      return transaction.type == currentTabType;
    }).toList();

    // Search (title, description, date)
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        final q = searchQuery.toLowerCase();
        return transaction.title.toLowerCase().contains(q) ||
              transaction.description.toLowerCase().contains(q) ||
              transaction.date.toLowerCase().contains(q);
      }).toList();
    }

    // Ambil hanya 5 terakhir
    if (filtered.length > 5) {
      filtered = filtered.sublist(0, 5);
    }

    return filtered;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(amount);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _extractTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '00:00';
    }
  }

  Future<void> _refreshTransactions() async {
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTransactions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildUserInfo(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildTabs(),
                    const SizedBox(height: 20),
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

  Widget _buildHeader() {
    return Container(
      height: 100, // Increased height for better visual balance
      width: double.infinity,
      decoration: BoxDecoration(
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
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        user: {
                          'nip': widget.nip,
                          'nama': widget.nama,
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF4E342E),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Transaksi',
                      style: TextStyle(
                        color: Color(0xFF4E342E),
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Detail aktivitas keuangan Anda',
                      style: TextStyle(
                        color: Color(0xFF4E342E).withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
                  color: Color(0xFF4E342E),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDC16).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDC16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFDC16),
            child: Text(
              widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Color(0xFF4E342E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E342E),
                  ),
                ),
                Text(
                  'NIP: ${widget.nip}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDC16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${filteredTransactions.length} Transaksi',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E342E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF4E342E),
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          hintText: 'Cari transaksi (judul / tanggal)...',
          hintStyle: TextStyle(
            color: Color(0x994E342E),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFFBCAAA4),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTab = 0;
                  });
                },
                child: Text(
                  tabs[0],
                  style: TextStyle(
                    color: selectedTab == 0
                        ? const Color(0xFF4E342E)
                        : const Color(0xCE4E342E),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (selectedTab == 0)
                Container(
                  height: 5,
                  width: 87,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDC16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: 4,
          height: 29,
          color: const Color(0xFFCCCCCC),
        ),
        Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTab = 1;
                  });
                },
                child: Text(
                  tabs[1],
                  style: TextStyle(
                    color: selectedTab == 1
                        ? const Color(0xFF4E342E)
                        : const Color(0xCE4E342E),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (selectedTab == 1)
                Container(
                  height: 5,
                  width: 87,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDC16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          children: [
            SizedBox(height: 50),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFDC16)),
            ),
            SizedBox(height: 16),
            Text(
              'Memuat riwayat transaksi...',
              style: TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final filteredList = filteredTransactions;

    if (filteredList.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildTransactionCard(filteredList[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada transaksi ${tabs[selectedTab].toLowerCase()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'untuk ${widget.nama}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refreshTransactions,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFDC16),
              foregroundColor: const Color(0xFF4E342E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem transaction) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDC16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              transaction.type == 'simpanan'
                  ? Icons.account_balance_wallet
                  : Icons.credit_card,
              color: const Color(0xFF4E342E),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: Color(0xFF4E342E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: Color(0xFF6D4C41),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: Color(0xFF8D6E63)),
                    const SizedBox(width: 4),
                    Text(
                      transaction.date,
                      style: const TextStyle(
                        color: Color(0xFF8D6E63),
                        fontSize: 12,
                      ),
                    ),
                    // Only show time if it's not "00:00"
                    if (transaction.time != '00:00') ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time,
                          size: 13, color: Color(0xFF8D6E63)),
                      const SizedBox(width: 4),
                      Text(
                        transaction.time,
                        style: const TextStyle(
                          color: Color(0xFF8D6E63),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            transaction.amount,
            style: TextStyle(
              color: (transaction.type == 'pinjaman')
                  ? const Color(0xFF4E342E) // netral coklat untuk pinjaman & pembayaran
                  : (transaction.isPositive ? Colors.green[700] : Colors.red),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

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

  TransactionItem({
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