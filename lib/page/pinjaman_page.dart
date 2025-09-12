import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PinjamanPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const PinjamanPage({super.key, required this.user});

  @override
  State<PinjamanPage> createState() => _PinjamanPageState();
}

class _PinjamanPageState extends State<PinjamanPage> with TickerProviderStateMixin {
  late Future<List<dynamic>> _futurePinjaman;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _futurePinjaman = ApiService.getPinjaman(widget.user['nip']);
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatRupiah(dynamic value) {
    if (value == null) return "Rp. 0";
    double val = double.tryParse(value.toString()) ?? 0;
    return "Rp. ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  String _formatText(dynamic value, {String defaultValue = "-"}) {
    return value?.toString() ?? defaultValue;
  }

  String _formatDate(dynamic value) {
    if (value == null) return "-";
    try {
      DateTime date = DateTime.parse(value.toString());
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return value.toString();
    }
  }

  List<Map<String, dynamic>> _categorizeLoans(List<dynamic> loans) {
    List<Map<String, dynamic>> regular = [];
    List<Map<String, dynamic>> usaha = [];
    List<Map<String, dynamic>> barang = [];

    for (var loan in loans) {
      String jenis = _formatText(loan['jenis_pinjaman']).toLowerCase();
      if (jenis.contains('usaha')) {
        usaha.add(loan);
      } else if (jenis.contains('barang')) {
        barang.add(loan);
      } else {
        regular.add(loan);
      }
    }

    return [
      {'type': 'regular', 'loans': regular, 'name': 'Pinjaman Reguler'},
      {'type': 'usaha', 'loans': usaha, 'name': 'Pinjaman Usaha'},
      {'type': 'barang', 'loans': barang, 'name': 'Pinjaman Barang'},
    ];
  }

  double _getTotalAmount(List<dynamic> loans, String field) {
    return loans.fold(0.0, (sum, loan) => 
      sum + (double.tryParse(loan[field]?.toString() ?? '0') ?? 0));
  }

  void _showLoanDetail(dynamic loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildLoanDetailSheet(loan, scrollController),
      ),
    );
  }

  Widget _buildLoanDetailSheet(dynamic loan, ScrollController scrollController) {
    String status = _formatText(loan['status'], defaultValue: 'Belum Lunas');
    bool isLunas = status.toLowerCase() == 'lunas';
    
    double jumlahPinjaman = double.tryParse(loan['jumlah_pinjaman']?.toString() ?? '0') ?? 0;
    double sisaPinjaman = double.tryParse(loan['sisa_pinjaman']?.toString() ?? '0') ?? 0;
    double sudahDibayar = jumlahPinjaman - sisaPinjaman;
    double progress = jumlahPinjaman > 0 ? sudahDibayar / jumlahPinjaman : 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLunas ? Colors.green[100] : Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLunas ? Icons.check_circle : Icons.account_balance_wallet,
                    color: isLunas ? Colors.green[700] : Colors.amber[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detail Pinjaman",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLunas ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLunas ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Progress Card
                if (!isLunas) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[600]!, Colors.amber[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Progress Pembayaran",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${(progress * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.black.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sudah Dibayar",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  _formatRupiah(sudahDibayar),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Sisa Pinjaman",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  _formatRupiah(sisaPinjaman),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Informasi Pinjaman
                _buildDetailSection(
                  "Informasi Pinjaman",
                  Icons.info_outline,
                  Colors.blue,
                  [
                    _buildDetailItem("Jenis Pinjaman", _formatText(loan['jenis_pinjaman'])),
                    _buildDetailItem("Nomor Pinjaman", _formatText(loan['id_pinjaman'] ?? loan['no_pinjaman'])),
                    _buildDetailItem("Tanggal Pinjaman", _formatDate(loan['tanggal_meminjam'])),
                    _buildDetailItem("Tanggal Jatuh Tempo", _formatDate(loan['tanggal_jatuh_tempo'])),
                    _buildDetailItem("Status", status),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Informasi Keuangan
                _buildDetailSection(
                  "Informasi Keuangan",
                  Icons.monetization_on,
                  Colors.green,
                  [
                    _buildDetailItem("Jumlah Pinjaman", _formatRupiah(loan['jumlah_pinjaman'])),
                    _buildDetailItem("Sisa Pinjaman", _formatRupiah(loan['sisa_pinjaman'])),
                    _buildDetailItem("Bunga", _formatText(loan['bunga'], defaultValue: "0.8%")),
                    _buildDetailItem("Tenor", "${_formatText(loan['tenor'], defaultValue: '12')} bulan"),
                    _buildDetailItem("Angsuran per Bulan", _formatRupiah(loan['angsuran_per_bulan'])),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Informasi Tambahan
                if (loan['keterangan'] != null || loan['tujuan'] != null) ...[
                  _buildDetailSection(
                    "Informasi Tambahan",
                    Icons.description,
                    Colors.orange,
                    [
                      if (loan['tujuan'] != null) 
                        _buildDetailItem("Tujuan", _formatText(loan['tujuan'])),
                      if (loan['keterangan'] != null) 
                        _buildDetailItem("Keterangan", _formatText(loan['keterangan'])),
                      _buildDetailItem("Disetujui Oleh", _formatText(loan['disetujui_oleh'], defaultValue: "Admin")),
                      _buildDetailItem("Tanggal Disetujui", _formatDate(loan['tanggal_disetujui'])),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Riwayat Pembayaran (jika ada)
                if (loan['riwayat_pembayaran'] != null) ...[
                  _buildDetailSection(
                    "Riwayat Pembayaran",
                    Icons.history,
                    Colors.purple,
                    [
                      _buildDetailItem("Pembayaran Terakhir", _formatDate(loan['pembayaran_terakhir'])),
                      _buildDetailItem("Jumlah Pembayaran Terakhir", _formatRupiah(loan['jumlah_pembayaran_terakhir'])),
                      _buildDetailItem("Sisa Angsuran", "${_formatText(loan['sisa_angsuran'], defaultValue: '0')} kali"),
                    ],
                  ),
                ],
                
                const SizedBox(height: 100), // Space for bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Color color, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Changed from amber to neutral grey
      appBar: AppBar(
        title: const Text(
          "Pinjaman",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white, // Changed from amber to white
        foregroundColor: Colors.black,
        elevation: 2, // Added slight elevation for separation
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futurePinjaman,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber) // Changed to amber
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futurePinjaman = ApiService.getPinjaman(widget.user['nip']);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber, // Added amber color
                    ),
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Belum ada pinjaman",
                    style: TextStyle(
                      color: Colors.black87, 
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Anda belum memiliki riwayat pinjaman",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final pinjamanList = snapshot.data!;
          final categorizedLoans = _categorizeLoans(pinjamanList);
          final totalSemua = _getTotalAmount(pinjamanList, 'sisa_pinjaman');

          return Column(
            children: [
              // Header Card dengan Info User
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // User Info
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber[600]!, Colors.amber[400]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.person,
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
                                _formatText(widget.user['nama'], defaultValue: 'Pengguna'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Pinjaman",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // NIP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "NIP",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatText(widget.user['nip'], defaultValue: '-'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Total Semua Pinjaman
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Semua Pinjaman",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatRupiah(totalSemua),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Breakdown by Category
                    ...categorizedLoans.map((category) {
                      final loans = category['loans'] as List<dynamic>;
                      final total = _getTotalAmount(loans, 'sisa_pinjaman');
                      final name = category['name'] as String;
                      
                      Color dotColor;
                      switch (category['type']) {
                        case 'regular':
                          dotColor = Colors.blue;
                          break;
                        case 'usaha':
                          dotColor = Colors.green;
                          break;
                        case 'barang':
                          dotColor = Colors.orange;
                          break;
                        default:
                          dotColor = Colors.grey;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            Text(
                              _formatRupiah(total),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              
              // Sisa Pinjaman Total Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[600]!, Colors.amber[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sisa Pinjaman (Total)",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(totalSemua),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tab Navigation
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    _buildTabButton(0, "Reguler", Icons.account_balance),
                    _buildTabButton(1, "Usaha", Icons.business),
                    _buildTabButton(2, "Barang", Icons.shopping_cart),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Content based on selected tab
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildTabContent(categorizedLoans[_selectedTabIndex]),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    bool isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber[600] : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> categoryData) {
    final loans = categoryData['loans'] as List<dynamic>;
    final categoryName = categoryData['name'] as String;
    final total = _getTotalAmount(loans, 'sisa_pinjaman');
    
    IconData categoryIcon;
    Color categoryColor;
    String description;
    
    switch (categoryData['type']) {
      case 'regular':
        categoryIcon = Icons.account_balance;
        categoryColor = Colors.blue;
        description = "Pinjaman reguler dengan suku bunga tetap, tenor hingga 24 bulan";
        break;
      case 'usaha':
        categoryIcon = Icons.business;
        categoryColor = Colors.green;
        description = "Untuk pengembangan usaha anggota dengan bunga kompetitif";
        break;
      case 'barang':
        categoryIcon = Icons.shopping_cart;
        categoryColor = Colors.orange;
        description = "Pinjaman untuk pembelian barang dengan cicilan tetap";
        break;
      default:
        categoryIcon = Icons.account_balance;
        categoryColor = Colors.grey;
        description = "Pinjaman umum";
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (loans.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: categoryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Total ${loans.length} pinjaman aktif dengan sisa ${_formatRupiah(total)}",
                          style: TextStyle(
                            fontSize: 11,
                            color: categoryColor.withAlpha(200),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Content
        if (loans.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    categoryIcon,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada $categoryName",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Anda belum memiliki pinjaman dalam kategori ini",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Riwayat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Riwayat $categoryName",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${loans.length} Pinjaman",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Loan List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: loans.length,
              itemBuilder: (context, index) {
                return _buildLoanItem(loans[index], categoryIcon, categoryColor);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoanItem(dynamic loan, IconData icon, Color color) {
    String status = _formatText(loan['status'], defaultValue: 'Belum Lunas');
    bool isLunas = status.toLowerCase() == 'lunas';
    
    double jumlahPinjaman = double.tryParse(loan['jumlah_pinjaman']?.toString() ?? '0') ?? 0;
    double sisaPinjaman = double.tryParse(loan['sisa_pinjaman']?.toString() ?? '0') ?? 0;
    double progress = jumlahPinjaman > 0 ? (jumlahPinjaman - sisaPinjaman) / jumlahPinjaman : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLoanDetail(loan),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isLunas ? Colors.green[600] : color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isLunas ? Icons.check_circle : icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatText(loan['jenis_pinjaman'], defaultValue: 'Pinjaman Reguler'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(loan['tanggal_meminjam']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (loan['tenor'] != null) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${_formatText(loan['tenor'])} bulan",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatRupiah(loan['sisa_pinjaman']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "dari ${_formatRupiah(loan['jumlah_pinjaman'])}",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLunas ? Colors.green[100] : Colors.amber[100], // Changed to amber
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isLunas ? "Lunas" : "Aktif",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isLunas ? Colors.green[700] : Colors.amber[700], // Changed to amber
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Progress Bar untuk pinjaman aktif
                if (!isLunas) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Progress Pembayaran",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ],
                
                // Tap indicator
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Ketuk untuk detail",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}