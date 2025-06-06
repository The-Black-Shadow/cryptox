import 'package:flutter/material.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;

  const CustomDropdownField({
    super.key,
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
    this.hint = "Select Coin", // Optional hint text
  });

  @override
  Widget build(BuildContext context) {
    String? dropdownValue = value;

    // This is a safety check: The value of a DropdownButton MUST be null or
    // one of the items in its list. This ensures the app doesn't crash if the
    // provided 'value' is not in the (potentially filtered) 'items' list.
    if (dropdownValue != null && !items.contains(dropdownValue)) {
      dropdownValue = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: dropdownValue, // Use the sanitized value
              hint: Text(
                hint!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
              items: items.map((itemValue) {
                return DropdownMenuItem(
                  value: itemValue,
                  child: Text(
                    itemValue,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis, // Prevent long text from overflowing
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              itemHeight: kMinInteractiveDimension, // Standard height for tap targets
            ),
          ),
        ),
      ],
    );
  }
}