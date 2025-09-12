import 'package:flutter/material.dart';
import 'tabungan_page.dart';
import 'history_page.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beranda"),
        backgroundColor: const Color.fromARGB(255, 242, 255, 254),
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Selamat Datang, ${user['nama']}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text("NIP: ${user['nip']}"),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TabunganPage(
                          nip: user['nip'],
                          nama: user['nama'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text("Lihat Tabungan"),
                ),

                const SizedBox(height: 10),

                // 🔹 Tombol History
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(
                          nip: user['nip'],
                          nama: user['nama'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text("Riwayat Transaksi"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
