import 'package:flutter/material.dart';
import 'package:dropdown_flutter/custom_dropdown.dart';

class CustomDropDown extends StatelessWidget {
  final List<String> items;
  final String hintText;
  final Function(String?) onChange;
  final String? initialValue;
  const CustomDropDown({
    super.key,
    required this.items,
    required this.hintText,
    required this.onChange,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownFlutter<String>(
        hintText: hintText,
        items: items,
        onChanged: onChange,
        initialItem: initialValue,
        decoration: CustomDropdownDecoration(
          closedFillColor: Colors.transparent, // important!
          expandedFillColor: Colors.black,
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontFamily: "Poppins",
            fontSize: 16,
          ),
          headerStyle: const TextStyle(
            color: Colors.white,
            fontFamily: "Poppins",
            fontSize: 16,
          ),
          listItemStyle: const TextStyle(
            color: Colors.white,
            fontFamily: "Poppins",
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
