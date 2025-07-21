import 'package:flutter/material.dart';

class OsaHomePage extends StatelessWidget {
  const OsaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Osa Admin'),
      ),
      body: const Center(
        child: Text('Osa Admin'),
      ),
    );
  }
}
