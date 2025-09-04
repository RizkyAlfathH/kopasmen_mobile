import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome ${user['nama']}")),
      body: Center(
        child: Text("NIP: ${user['nip']}\nEmail: ${user['email']}"),
      ),
    );
  }
}
