import 'package:flutter/material.dart';

/// A reusable text form field component that can be customized for different use cases.
Widget reusableTextField({
  required TextEditingController controller,
  required String labelText,
  required String? Function(String?)? validator,
  IconData? prefixIcon,
  Widget? suffixIcon,
  bool obscureText = false,
  Color? fillColor,
  TextStyle? labelStyle,
  TextStyle? hintStyle,
  String? hintText,
  void Function(String)? onChanged,
  TextInputType? keyboardType,
}) {
  // final Color themeColor = Colors.blue.shade600;
  const Color themeColor = Color(0xFF1A1851);

  return Theme(
    data: ThemeData(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: themeColor,
        selectionColor: themeColor.withOpacity(0.3),
        selectionHandleColor: themeColor,
      ),
    ),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle:
            labelStyle ?? TextStyle(color: Colors.black.withOpacity(0.7)),
        hintText: hintText,
        hintStyle: hintStyle ?? const TextStyle(color: Colors.grey),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: themeColor.withOpacity(0.7))
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: fillColor ?? Colors.grey[100],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: themeColor, width: 1.5),
        ),
        focusColor: themeColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      cursorColor: themeColor,
      cursorWidth: 1.5,
      cursorRadius: const Radius.circular(2),
      style: const TextStyle(color: Colors.black87),
    ),
  );
}





//  decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue.shade50, Colors.white],
//           ),
//         ),