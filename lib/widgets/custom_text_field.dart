import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final Widget icon;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly; // <-- add
  final VoidCallback? onTap; // <-- add

  const CustomTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.readOnly = false, // <-- default false
    this.onTap, // <-- optional
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.kanit(color: Colors.white, fontSize: 16),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly, // <-- add this
      onTap: onTap,
      decoration: InputDecoration(
        prefixIcon: Padding(padding: const EdgeInsets.all(12.0), child: icon),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: GoogleFonts.kanit(color: Colors.white70, fontSize: 16),
        filled: true,
        fillColor: const Color(0xFFC98993),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: GoogleFonts.kanit(color: Colors.white),
      ),
    );
  }
}
