import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
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
  int selectedFilter = 0;
  int selectedTab = 0;
  bool isLoading = false;
  List<TransactionItem> transactions = [];
  String searchQuery = '';

  final List<String> filterOptions = ['Semua', '1 minggu', '1 Bulan', '3 Bulan'];
  final List<String> tabs = ['Simpanan', 'Pinjaman'];

  List<dynamic> _simpananData = [];
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
      // Fetch data from API services
      await Future.wait([
        _fetchSimpananData(),
        _fetchPinjamanData(),
      ]);

      // Process and combine the data
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

  void _processTransactionData() {
    List<TransactionItem> processedTransactions = [];

    // Process Simpanan data
    for (var item in _simpananData) {
      final amount = double.tryParse(item['nominal'].toString()) ?? 0;
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString();
      final tanggal = item['tanggal_menyimpan'].toString();
      
      processedTransactions.add(TransactionItem(
        id: '${widget.nip}_simpanan_${item['id']}',
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

    // Process Pinjaman data
    for (var item in _pinjamanData) {
      final amount = double.tryParse(item['nominal'].toString()) ?? 0;
      final jenisNama = item['jenis_pinjaman']['nama_jenis'].toString();
      final tanggal = item['tanggal_meminjam'].toString();
      
      // Add pinjaman (loan disbursement) as positive transaction
      processedTransactions.add(TransactionItem(
        id: '${widget.nip}_pinjaman_${item['id']}',
        title: 'Pencairan $jenisNama',
        description: 'Pinjaman $jenisNama - ${widget.nama}',
        amount: '+ Rp ${_formatCurrency(amount)}',
        date: _formatDate(tanggal),
        time: _extractTime(tanggal),
        isPositive: true,
        type: 'pinjaman',
        userNip: widget.nip,
        rawData: item,
      ));

      // If there are installment records, add them as negative transactions
      if (item['angsuran'] != null && item['angsuran'] is List) {
        List<dynamic> angsuranList = item['angsuran'];
        for (var angsuran in angsuranList) {
          final angsuranAmount = double.tryParse(angsuran['nominal'].toString()) ?? 0;
          final angsuranTanggal = angsuran['tanggal_bayar'].toString();
          
          processedTransactions.add(TransactionItem(
            id: '${widget.nip}_angsuran_${angsuran['id']}',
            title: 'Angsuran $jenisNama',
            description: 'Pembayaran cicilan $jenisNama - ${widget.nama}',
            amount: '- Rp ${_formatCurrency(angsuranAmount)}',
            date: _formatDate(angsuranTanggal),
            time: _extractTime(angsuranTanggal),
            isPositive: false,
            type: 'pinjaman',
            userNip: widget.nip,
            rawData: angsuran,
          ));
        }
      }
    }

    // Sort transactions by date (newest first)
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

    // Filter by tab
    final currentTabType = tabs[selectedTab].toLowerCase();
    filtered = filtered.where((transaction) {
      return transaction.type == currentTabType;
    }).toList();

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
               transaction.description.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by time period
    if (selectedFilter > 0) {
      final now = DateTime.now();
      DateTime cutoffDate;
      
      switch (selectedFilter) {
        case 1: // 1 minggu
          cutoffDate = now.subtract(Duration(days: 7));
          break;
        case 2: // 1 Bulan
          cutoffDate = now.subtract(Duration(days: 30));
          break;
        case 3: // 3 Bulan
          cutoffDate = now.subtract(Duration(days: 90));
          break;
        default:
          cutoffDate = DateTime(2000); // Very old date to include all
      }

      filtered = filtered.where((transaction) {
        try {
          final transactionDate = DateTime.parse(
            transaction.rawData['tanggal_menyimpan'] ?? 
            transaction.rawData['tanggal_meminjam'] ?? 
            transaction.rawData['tanggal_bayar'] ?? 
            DateTime.now().toString()
          );
          return transactionDate.isAfter(cutoffDate);
        } catch (e) {
          return true; // Include if date parsing fails
        }
      }).toList();
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
      return dateString; // Return original if parsing fails
    }
  }

  String _extractTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '00:00'; // Default time if parsing fails
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
                    _buildFilterOptions(),
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
      height: 72,
      width: double.infinity,
      color: const Color(0xFFFFDC16),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF4E342E),
            ),
          ),
          const SizedBox(width: 15),
          const Text(
            'Riwayat Transaksi',
            style: TextStyle(
              color: Color(0xFF4E342E),
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCCCCC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Cari Transaksi...',
          hintStyle: TextStyle(
            color: Color(0xBF4E342E),
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xBF4E342E),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return SizedBox(
      height: 25,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = selectedFilter == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFDC16) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCCCCCC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  filterOptions[index],
                  style: TextStyle(
                    color: isSelected 
                        ? const Color(0xFF4E342E) 
                        : const Color(0xB24E342E),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
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
                    fontFamily: 'Poppins',
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
                    fontFamily: 'Poppins',
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
      separatorBuilder: (context, index) => const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFCCCCCC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDC16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.type == 'simpanan' 
                  ? Icons.account_balance_wallet
                  : Icons.credit_card,
              color: const Color(0xFF4E342E),
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: Color(0xFF4E342E),
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: Color(0xFF4E342E),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xB74E342E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      transaction.date,
                      style: const TextStyle(
                        color: Color(0xB74E342E),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xB74E342E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      transaction.time,
                      style: const TextStyle(
                        color: Color(0xB74E342E),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.amount,
                style: TextStyle(
                  color: transaction.isPositive 
                      ? const Color(0xFF008F09) 
                      : Colors.red,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: transaction.type == 'simpanan' 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.type.toUpperCase(),
                  style: TextStyle(
                    color: transaction.type == 'simpanan' 
                        ? Colors.blue
                        : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
  final String type; // 'simpanan' or 'pinjaman'
  final String userNip;
  final dynamic rawData; // Store original API data for reference

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

class BottomNavItem {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  BottomNavItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
}