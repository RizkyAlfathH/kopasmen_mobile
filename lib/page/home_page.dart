import 'package:flutter/material.dart';
import 'pinjaman_page.dart';
import 'tabungan_page.dart';
import 'history_page.dart';
import 'profile_page.dart';


class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // ✅ default ke Home

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      TabunganPage(
        nip: widget.user['nip'],
        nama: widget.user['nama'],
      ),
      PinjamanPage(user: widget.user),
      _buildHomeContent(), // halaman home
      HistoryPage(
        nip: widget.user['nip'],
        nama: widget.user['nama'],
      ),
      ProfilePage(nip: widget.user['nip']),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.yellow[600],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: "Simpanan"),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "Pinjaman"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // ✅ Halaman Home
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.yellow[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Selamat Datang",
                          style: TextStyle(fontSize: 14, color: Colors.black)),
                      Text(
                        widget.user['nama'] ?? "Nama Anggota",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.notifications_none, color: Colors.black),
              ],
            ),
          ),

          // Profil
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.brown),
                    const SizedBox(width: 8),
                    Text(widget.user['nama'] ?? "Nama Anggota",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("NIP : ",
                        style: TextStyle(color: Colors.black54)),
                    Text(widget.user['nip'] ?? "-",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                )
              ],
            ),
          ),

          // Simpanan
          _buildSectionTitle("Simpanan"),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildSimpananCard(Icons.account_balance, "Simpanan Pokok", "Rp. 500.000"),
                  _buildSimpananCard(Icons.account_balance_wallet, "Simpanan Wajib", "Rp. 200.000"),
                  _buildSimpananCard(Icons.savings, "Simpanan Sukarela", "Rp. 300.000"),
                ],
              ),
            ),
          ),

          // Pinjaman
          _buildSectionTitle("Pinjaman"),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Total Pinjaman", style: TextStyle(color: Colors.black54)),
                SizedBox(height: 4),
                Text("Rp. 20.000.000",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),
                Text("Total Tagihan Bulan Ini",
                    style: TextStyle(color: Colors.black54)),
                Text("Rp. xxx.xxx",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),

          // History Section
          _buildSectionTitle("History"),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildHistoryItem(Icons.payment, "Pembayaran Pinjaman", "10 Mei 2025", "- Rp. 500.000", false),
              _buildHistoryItem(Icons.savings, "Setoran Wajib", "11 Mei 2025", "+ Rp. 200.000", true),
              _buildHistoryItem(Icons.savings, "Setoran Sukarela", "12 Mei 2025", "+ Rp. 300.000", true),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget Reusable ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSimpananCard(IconData icon, String title, String saldo) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.brown, size: 18),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Saldo", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(saldo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
      IconData icon, String title, String date, String amount, bool isPositive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.yellow[100],
            child: Icon(icon, color: Colors.brown, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Text(amount,
              style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
