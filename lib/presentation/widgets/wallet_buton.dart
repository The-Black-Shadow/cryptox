import 'package:flutter/material.dart';

class WalletButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed; // To handle tap events

  const WalletButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed, // Make onPressed optional if some buttons don't do anything, or required if they always do
  });

  @override
  Widget build(BuildContext context) {
    // The build method directly returns the ElevatedButton.icon
    return ElevatedButton.icon(
      onPressed: onPressed, // Use the onPressed callback passed to the widget
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}