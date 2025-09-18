import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class PinjamanPage extends StatefulWidget {
  final String nip;
  final String nama;

  const PinjamanPage({super.key, required this.nip, required this.nama});

  @override
  State<PinjamanPage> createState() => _PinjamanPageState();
}

class _PinjamanPageState extends State<PinjamanPage> with SingleTickerProviderStateMixin {
  List<dynamic> pinjamanList = [];
  bool isLoading = true;
  late TabController _tabController;
  
  // Calculated totals
  double totalPinjamanReguler = 0;
  double totalPinjamanKhusus = 0;
  double totalPinjamanBarang = 0;
  double totalSisaPinjamanReguler = 0;
  double totalSisaPinjamanKhusus = 0;
  double totalSisaPinjamanBarang = 0;
  double grandTotalPinjaman = 0;
  double grandTotalSisaPinjaman = 0;

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
      final data = await ApiService.getPinjaman(widget.nip);
        setState(() {
          pinjamanList = data; 
          _calculateTotals();
          isLoading = false;
        });

        for (var p in pinjamanList) {
  print("ID Pinjaman: ${p['id_pinjaman']}, Sisa: ${p['sisa_pinjaman']}");
}
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      final nominal = double.tryParse(item['nominal'].toString()) ?? 0;
      final sisaPinjaman = double.tryParse(item['sisa_pinjaman'].toString()) ?? 0;
      final jenisNama = item['jenis_pinjaman']?['nama_jenis']?.toString().toLowerCase() ?? '';
      
      if (jenisNama.contains('reguler') || jenisNama.contains('biasa')) {
        totalPinjamanReguler += nominal;
        totalSisaPinjamanReguler += sisaPinjaman;
      } else if (jenisNama.contains('khusus') || jenisNama.contains('darurat')) {
        totalPinjamanKhusus += nominal;
        totalSisaPinjamanKhusus += sisaPinjaman;
      } else if (jenisNama.contains('barang') || jenisNama.contains('elektronik')) {
        totalPinjamanBarang += nominal;
        totalSisaPinjamanBarang += sisaPinjaman;
      } else {
        // Default ke reguler jika tidak dikenali
        totalPinjamanReguler += nominal;
        totalSisaPinjamanReguler += sisaPinjaman;
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
                 (!jenisNama.contains('khusus') && !jenisNama.contains('darurat') && 
                  !jenisNama.contains('barang') && !jenisNama.contains('elektronik'));
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
      case 'reguler':
        return Icons.credit_card;
      case 'khusus':
        return Icons.priority_high;
      case 'barang':
        return Icons.shopping_cart;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'reguler':
        return const Color(0xFF1976D2);
      case 'khusus':
        return const Color(0xFFD32F2F);
      case 'barang':
        return const Color(0xFF7B1FA2);
      default:
        return const Color(0xFF4E342E);
    }
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('lunas') && !statusLower.contains('belum')) {
      return const Color(0xFF4CAF50);
    } else if (statusLower.contains('belum lunas') || statusLower.contains('pending')) {
      return const Color(0xFFFF9800);
    } else if (statusLower.contains('ditolak') || statusLower.contains('gagal')) {
      return const Color(0xFFD32F2F);
    } else {
      return const Color(0xFF757575);
    }
  }

  IconData _getStatusIcon(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('lunas') && !statusLower.contains('belum')) {
      return Icons.check_circle;
    } else if (statusLower.contains('belum lunas') || statusLower.contains('pending')) {
      return Icons.schedule;
    } else if (statusLower.contains('ditolak') || statusLower.contains('gagal')) {
      return Icons.error;
    } else {
      return Icons.info;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(amount);
  }

  double _calculateMonthlyPayment(double remainingBalance) {
    if (remainingBalance <= 0) return 0;
    
    // Simple calculation - you can adjust this based on your business logic
    // This assumes a 12-month payment period, but you can customize it
    // You might want to get the actual loan terms from your data
    const int monthsRemaining = 12; // or get from loan data
    return remainingBalance / monthsRemaining;
  }

  String _getMonthName() {
    final now = DateTime.now();
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return monthNames[now.month - 1];
  }

  @override
  Widget build(BuildContext context) {
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
                    'Memuat data pinjaman...',
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
          : NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: 480.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFFFFDC16),
                    elevation: 0,
                    leading: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF4E342E),
                          size: 20,
                        ),
                      ),
                    ),
                    title: Text(
                      'Pinjaman',
                      style: TextStyle(
                        color: Color(0xFF4E342E),
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
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
                            padding: const EdgeInsets.fromLTRB(25, 60, 25, 20),
                            child: Column(
                              children: [
                                // User Info Card
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
                                                widget.nama,
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
                                                      'NIP: ${widget.nip}',
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

                                const SizedBox(height: 24),

                                // Summary Cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickSummaryCard(
                                        'Total Pinjaman', 
                                        grandTotalPinjaman, 
                                        Icons.trending_up, 
                                        Color(0xFF1976D2)
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickSummaryCard(
                                        'Sisa Tagihan', 
                                        grandTotalSisaPinjaman, 
                                        Icons.pending_actions, 
                                        Color(0xFFFF9800)
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Status Card
                                Container(
                                  width: double.infinity,
                                  decoration: ShapeDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Color(0xFFFAFAFA),
                                      ],
                                    ),
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
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFFFDC16), Color(0xFFFFE554)],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0xFFFFDC16).withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.account_balance_wallet,
                                                color: Color(0xFF3E2723),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Status Keuangan',
                                                    style: TextStyle(
                                                      color: Color(0xFF3E2723),
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    grandTotalSisaPinjaman > 0 
                                                        ? 'Masih Ada Tanggungan' 
                                                        : pinjamanList.isEmpty 
                                                            ? 'Belum Ada Pinjaman' 
                                                            : 'Semua Pinjaman Lunas',
                                                    style: TextStyle(
                                                      color: grandTotalSisaPinjaman > 0 
                                                          ? Color(0xFFFF9800) 
                                                          : pinjamanList.isEmpty 
                                                              ? Color(0xFF757575) 
                                                              : Color(0xFF4CAF50),
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (grandTotalSisaPinjaman > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFFF9800).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: Color(0xFFFF9800).withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  '${pinjamanList.where((p) => (double.tryParse(p['sisa_pinjaman'].toString()) ?? 0) > 0).length} aktif',
                                                  style: TextStyle(
                                                    color: Color(0xFFFF9800),
                                                    fontSize: 12,
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
                                ),
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
                  // Tab Navigation
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card, size: 18),
                              SizedBox(width: 6),
                              Text('Reguler'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.priority_high, size: 18),
                              SizedBox(width: 6),
                              Text('Khusus'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart, size: 18),
                              SizedBox(width: 6),
                              Text('Barang'),
                            ],
                          ),
                        ),
                      ],
                      labelColor: const Color(0xFF4E342E),
                      unselectedLabelColor: const Color(0x7F4E342E),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                      indicator: BoxDecoration(
                        color: Color(0xFFFFDC16),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFDC16).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                    ),
                  ),

                  // Tab Content
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

  Widget _buildQuickSummaryCard(String title, double amount, IconData icon, Color color) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${_formatCurrency(amount)}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String type) {
    final filteredData = _getFilteredPinjaman(type);
    final totalPinjaman = type == 'reguler' ? totalPinjamanReguler : 
                         type == 'khusus' ? totalPinjamanKhusus : totalPinjamanBarang;
    final totalSisaPinjaman = type == 'reguler' ? totalSisaPinjamanReguler : 
                             type == 'khusus' ? totalSisaPinjamanKhusus : totalSisaPinjamanBarang;

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getColorForType(type).withOpacity(0.1),
                    _getColorForType(type).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                _getIconForType(type),
                size: 48,
                color: _getColorForType(type).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada pinjaman ${type}',
              style: TextStyle(
                color: _getColorForType(type),
                fontSize: 18,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data akan muncul setelah Anda mengajukan pinjaman ${type}',
              style: TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Summary Card for selected tab
                Container(
                  width: double.infinity,
                  decoration: ShapeDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getColorForType(type).withOpacity(0.1),
                        _getColorForType(type).withOpacity(0.05),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 2, color: _getColorForType(type).withOpacity(0.3)),
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
                                    _getColorForType(type),
                                    _getColorForType(type).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getColorForType(type).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getIconForType(type),
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
                                    'Pinjaman ${type.substring(0, 1).toUpperCase()}${type.substring(1)}',
                                    style: TextStyle(
                                      color: _getColorForType(type),
                                      fontSize: 18,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total yang telah dipinjam',
                                    style: TextStyle(
                                      color: _getColorForType(type).withOpacity(0.7),
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
                                  Text(
                                    'Total Pinjaman',
                                    style: TextStyle(
                                      color: _getColorForType(type).withOpacity(0.7),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${_formatCurrency(totalPinjaman)}',
                                    style: TextStyle(
                                      color: _getColorForType(type),
                                      fontSize: 20,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 40,
                              color: _getColorForType(type).withOpacity(0.3),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Sisa Tagihan',
                                    style: TextStyle(
                                      color: _getColorForType(type).withOpacity(0.7),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${_formatCurrency(totalSisaPinjaman)}',
                                    style: TextStyle(
                                      color: totalSisaPinjaman > 0 
                                          ? Color(0xFFD32F2F) 
                                          : Color(0xFF4CAF50),
                                      fontSize: 20,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Monthly Payment Section
                        if (totalSisaPinjaman > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF9800).withOpacity(0.1),
                                  Color(0xFFFF9800).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Color(0xFFFF9800).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFFFF9800).withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.schedule,
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
                                        'Tagihan Bulan Ini',
                                        style: TextStyle(
                                          color: Color(0xFFFF9800),
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rp ${_formatCurrency(_calculateMonthlyPayment(totalSisaPinjaman))}',
                                        style: TextStyle(
                                          color: Color(0xFFFF9800),
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF9800).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getMonthName(),
                                    style: TextStyle(
                                      color: Color(0xFFFF9800),
                                      fontSize: 10,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        Text(
                          '${filteredData.length} pinjaman terdaftar',
                          style: TextStyle(
                            color: _getColorForType(type).withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Transaction List Header
                Row(
                  children: [
                    Text(
                      'Riwayat Pinjaman',
                      style: TextStyle(
                        color: Color(0xFF4E342E),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getColorForType(type).withOpacity(0.1),
                            _getColorForType(type).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getColorForType(type).withOpacity(0.3)),
                      ),
                      child: Text(
                        '${filteredData.length} item',
                        style: TextStyle(
                          color: _getColorForType(type),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        
        // Loan List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final pinjaman = filteredData[index];
                final idPinjaman = pinjaman['id_pinjaman']?.toString() ?? "-";
                final jenisPinjaman = pinjaman['jenis_pinjaman']?['nama_jenis']?.toString() ?? "Tidak diketahui";
                final nominal = double.tryParse(pinjaman['nominal'].toString()) ?? 0;
                final sisaTagihan = double.tryParse(pinjaman['sisa_pinjaman'].toString()) ?? 0;
                final status = pinjaman['status']?.toString() ?? "-";
                final progress = nominal > 0 ? ((nominal - sisaTagihan) / nominal).clamp(0.0, 1.0) : 0.0;
                final monthlyPayment = _calculateMonthlyPayment(sisaTagihan);
                
                return Padding(
                  padding: EdgeInsets.only(bottom: index == filteredData.length - 1 ? 20 : 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color(0xFFFDFDFD),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getColorForType(type),
                                      _getColorForType(type).withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getColorForType(type).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getIconForType(type),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      jenisPinjaman,
                                      style: const TextStyle(
                                        color: Color(0xFF4E342E),
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'ID: $idPinjaman',
                                        style: const TextStyle(
                                          color: Color(0xFF757575),
                                          fontSize: 11,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getStatusColor(status).withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(status),
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status,
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
                          
                          const SizedBox(height: 20),
                          
                          // Amount Details
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getColorForType(type).withOpacity(0.05),
                                  _getColorForType(type).withOpacity(0.02),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _getColorForType(type).withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.trending_up,
                                              size: 16,
                                              color: Color(0xFF1976D2),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Nominal Pinjaman',
                                              style: TextStyle(
                                                color: Color(0xFF757575),
                                                fontSize: 12,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Rp ${_formatCurrency(nominal)}',
                                          style: TextStyle(
                                            color: Color(0xFF1976D2),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.pending_actions,
                                              size: 16,
                                              color: sisaTagihan > 0 ? Color(0xFFD32F2F) : Color(0xFF4CAF50),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Sisa Tagihan',
                                              style: TextStyle(
                                                color: Color(0xFF757575),
                                                fontSize: 12,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Rp ${_formatCurrency(sisaTagihan)}',
                                          style: TextStyle(
                                            color: sisaTagihan > 0 ? Color(0xFFD32F2F) : Color(0xFF4CAF50),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                // Monthly Payment for Individual Loan
                                if (sisaTagihan > 0) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFF9800).withOpacity(0.1),
                                          Color(0xFFFF9800).withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Color(0xFFFF9800).withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          color: Color(0xFFFF9800),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Tagihan Bulan Ini: ',
                                          style: TextStyle(
                                            color: Color(0xFF757575),
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Rp ${_formatCurrency(monthlyPayment)}',
                                          style: TextStyle(
                                            color: Color(0xFFFF9800),
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Progress Pembayaran',
                                            style: TextStyle(
                                              color: Color(0xFF757575),
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${(progress * 100).toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: _getColorForType(type),
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE0E0E0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: progress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getColorForType(type),
                                                  _getColorForType(type).withOpacity(0.8),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _getColorForType(type).withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'PINJAMAN LUNAS',
                                          style: TextStyle(
                                            color: Colors.white,
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: filteredData.length,
            ),
          ),
        ),
      ],
    );
  }
}