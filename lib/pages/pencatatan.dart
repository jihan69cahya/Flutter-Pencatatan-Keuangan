import 'package:flutter/material.dart';

class Pencatatan extends StatefulWidget {
  const Pencatatan({super.key});

  @override
  State<Pencatatan> createState() => _PencatatanState();
}

class _PencatatanState extends State<Pencatatan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pencatatan'),
        backgroundColor: Color(0xFF2a5298),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
