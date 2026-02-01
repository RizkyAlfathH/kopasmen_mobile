import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class TabunganPage extends StatefulWidget {
  final String nip;
  final String nama; // Add nama parameter for display

  const TabunganPage({super.key, required this.nip, this.nama = "User"});

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> with SingleTickerProviderStateMixin {
  List<dynamic> _simpanan = [];
  bool _loading = true;
  late TabController _tabController;
  
  // Calculated totals
  double _simpananPokok = 0;
  double _simpananWajib = 0;
  double _simpananSukarela = 0;
  double _totalSimpanan = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSimpanan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSimpanan() async {
    try {
      final data = await ApiService.getSimpanan(widget.nip);
      setState(() {
        _simpanan = data;
        _calculateTotals();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
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
    _simpananPokok = 0;
    _simpananWajib = 0;
    _simpananSukarela = 0;

    for (var item in _simpanan) {
      final nominal = double.tryParse(item['nominal'].toString()) ?? 0;
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString().toLowerCase();
      
      if (jenisNama.contains('pokok')) {
        _simpananPokok += nominal;
      } else if (jenisNama.contains('wajib')) {
        _simpananWajib += nominal;
      } else if (jenisNama.contains('sukarela')) {
        _simpananSukarela += nominal;
      }
    }
    
    _totalSimpanan = _simpananPokok + _simpananWajib + _simpananSukarela;
  }

  List<dynamic> _getFilteredSimpanan(String type) {
    return _simpanan.where((item) {
      final jenisNama = item['jenis_simpanan']['nama_jenis'].toString().toLowerCase();
      return jenisNama.contains(type.toLowerCase());
    }).toList();
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pokok':
        return Icons.account_balance;
      case 'wajib':
        return Icons.savings;
      case 'sukarela':
        return Icons.volunteer_activism;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'pokok':
        return const Color(0xFF2E7D32);
      case 'wajib':
        return const Color(0xFF1976D2);
      case 'sukarela':
        return const Color(0xFF7B1FA2);
      default:
        return const Color(0xFF4E342E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
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
                    'Memuat data simpanan...',
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
                    expandedHeight: 500.0,
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
                      'Simpanan',
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
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
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
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFFFDC16), Color(0xFFFFE554)],
                                                ),
                                                borderRadius: BorderRadius.circular(25),
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                color: Color(0xFF4E342E),
                                                size: 28,
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
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.badge,
                                                        size: 16,
                                                        color: Color(0xFF757575),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'NIP: ${widget.nip}',
                                                        style: const TextStyle(
                                                          color: Color(0xFF757575),
                                                          fontSize: 14,
                                                          fontFamily: 'Poppins',
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
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

                                const SizedBox(height: 40),

                                // Summary Card
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
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
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
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFE8F5E8),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.account_balance,
                                                color: Color(0xFF2E7D32),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Ringkasan Simpanan',
                                              style: TextStyle(
                                                color: Color(0xFF3E2723),
                                                fontSize: 16,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildSummaryRow('Simpanan Pokok', _simpananPokok, Icons.account_balance, Color(0xFF2E7D32)),
                                        const SizedBox(height: 12),
                                        _buildSummaryRow('Simpanan Wajib', _simpananWajib, Icons.savings, Color(0xFF1976D2)),
                                        const SizedBox(height: 12),
                                        _buildSummaryRow('Simpanan Sukarela', _simpananSukarela, Icons.volunteer_activism, Color(0xFF7B1FA2)),
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          height: 1,
                                          decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFFFFDC16), Color(0xFFFFE554)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.account_balance_wallet,
                                                color: Color(0xFF3E2723),
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Total Simpanan',
                                                      style: TextStyle(
                                                        color: Color(0xFF3E2723),
                                                        fontSize: 14,
                                                        fontFamily: 'Poppins',
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Rp ${_formatCurrency(_totalSimpanan)}',
                                                      style: const TextStyle(
                                                        color: Color(0xFF3E2723),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
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
                              Icon(Icons.account_balance, size: 18),
                              SizedBox(width: 6),
                              Text('Pokok'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.savings, size: 18),
                              SizedBox(width: 6),
                              Text('Wajib'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.volunteer_activism, size: 18),
                              SizedBox(width: 6),
                              Text('Sukarela'),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                    ),
                  ),

                  // Tab Content - FIXED: Wrap with Flexible instead of Expanded
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

  Widget _buildSummaryRow(String title, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF3E2723),
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          'Rp ${_formatCurrency(amount)}',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(String type) {
    final filteredData = _getFilteredSimpanan(type);
    final total = type == 'pokok' ? _simpananPokok : 
                  type == 'wajib' ? _simpananWajib : _simpananSukarela;

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                _getIconForType(type),
                size: 48,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data simpanan ${type}',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data akan muncul setelah Anda melakukan simpanan',
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

    // FIXED: Use CustomScrollView instead of SingleChildScrollView with ListView
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
                        blurRadius: 10,
                        offset: Offset(0, 4),
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getColorForType(type),
                                borderRadius: BorderRadius.circular(16),
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
                                    'Simpanan ${type.substring(0, 1).toUpperCase()}${type.substring(1)}',
                                    style: TextStyle(
                                      color: _getColorForType(type),
                                      fontSize: 18,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total yang telah dibayarkan',
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
                        Text(
                          'Rp ${_formatCurrency(total)}',
                          style: TextStyle(
                            color: _getColorForType(type),
                            fontSize: 28,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${filteredData.length} transaksi',
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
                      'Riwayat Transaksi',
                      style: TextStyle(
                        color: Color(0xFF4E342E),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getColorForType(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
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
        
        // FIXED: Use SliverList for the transaction items
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = filteredData[index];
                final amount = double.tryParse(item['nominal'].toString()) ?? 0;
                
                return Padding(
                  padding: EdgeInsets.only(bottom: index == filteredData.length - 1 ? 20 : 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getColorForType(type),
                              _getColorForType(type).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getIconForType(type),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        item['jenis_simpanan']['nama_jenis'],
                        style: const TextStyle(
                          color: Color(0xFF4E342E),
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Color(0xFF757575),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['tanggal_menyimpan'],
                              style: const TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Rp ${_formatCurrency(amount)}",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _getColorForType(type),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Berhasil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(amount); 
  }
}