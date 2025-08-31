import 'package:flutter/material.dart';

/// A reusable text form field component that can be customized for different use cases.
///
/// Use [showToggle] to enable a built-in eye icon for toggling password visibility.
Widget reusableTextField({
  required TextEditingController controller,
  required String labelText,
  required String? Function(String?)? validator,
  IconData? prefixIcon,
  Widget? suffixIcon,
  bool obscureText = false,
  bool showToggle = false,
  Color? fillColor,
  TextStyle? labelStyle,
  TextStyle? hintStyle,
  String? hintText,
  void Function(String)? onChanged,
  TextInputType? keyboardType,
}) {
  return ReusableTextField(
    controller: controller,
    labelText: labelText,
    validator: validator,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    obscureText: obscureText,
    showToggle: showToggle,
    fillColor: fillColor,
    labelStyle: labelStyle,
    hintStyle: hintStyle,
    hintText: hintText,
    onChanged: onChanged,
    keyboardType: keyboardType,
  );
}

class ReusableTextField extends StatefulWidget {
  const ReusableTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.showToggle = false,
    this.fillColor,
    this.labelStyle,
    this.hintStyle,
    this.hintText,
    this.onChanged,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool showToggle;
  final Color? fillColor;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final String? hintText;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;

  @override
  State<ReusableTextField> createState() => _ReusableTextFieldState();
}

class _ReusableTextFieldState extends State<ReusableTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF1A1851);
    Widget? suffix = widget.suffixIcon;
    if (widget.showToggle) {
      suffix = IconButton(
        icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade700),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }

    return Theme(
      data: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: themeColor,
          selectionColor: themeColor.withOpacity(0.3),
          selectionHandleColor: themeColor,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: widget.labelStyle ??
              TextStyle(color: Colors.black.withOpacity(0.7)),
          hintText: widget.hintText,
          hintStyle: widget.hintStyle ?? const TextStyle(color: Colors.grey),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: themeColor.withOpacity(0.7))
              : null,
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: widget.fillColor ?? Colors.grey[100],
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
        obscureText: _obscured,
        validator: widget.validator,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        cursorColor: themeColor,
        cursorWidth: 1.5,
        cursorRadius: const Radius.circular(2),
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}





//  decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue.shade50, Colors.white],
//           ),
//         ),