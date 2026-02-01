import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TabunganPage extends StatefulWidget {
  final String nip;

  const TabunganPage({super.key, required this.nip});

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> {
  List<dynamic> _simpanan = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSimpanan();
  }

  Future<void> _fetchSimpanan() async {
    final data = await ApiService.getSimpanan(widget.nip);
    setState(() {
      _simpanan = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tabungan Saya"),
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _simpanan.isEmpty
              ? const Center(child: Text("Belum ada data simpanan."))
              : ListView.builder(
                  itemCount: _simpanan.length,
                  itemBuilder: (context, index) {
                    final item = _simpanan[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(item['jenis_simpanan']['nama_jenis']),
                        subtitle: Text("Tanggal: ${item['tanggal_menyimpan']}"),
                        trailing: Text(
                          "Rp ${item['nominal']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
