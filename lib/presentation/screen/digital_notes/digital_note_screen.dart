import 'package:flutter/material.dart';

class DigitalNoteScreen extends StatefulWidget {
  const DigitalNoteScreen({super.key});

  @override
  State<DigitalNoteScreen> createState() => _DigitalNoteScreenState();
}

class _DigitalNoteScreenState extends State<DigitalNoteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Notes')),
      body: Center(child: Text('Digital Notes Screen')),
    );
  }
}
