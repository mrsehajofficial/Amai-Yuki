// premium_text_field.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const PremiumTextField({super.key, required this.controller, required this.labelText, required this.hintText, this.obscureText = false, this.prefixIcon, this.suffixIcon, this.keyboardType = TextInputType.text, this.textInputAction = TextInputAction.next});

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() { super.initState(); _focusNode = FocusNode(); _focusNode.addListener(() { setState(() { _isFocused = _focusNode.hasFocus; }); }); }
  @override
  void dispose() { _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText.isNotEmpty) ...[Text(widget.labelText, style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 8)],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: _isFocused ? [BoxShadow(color: AppColors.borderHigh.withOpacity(0.05), blurRadius: 8, spreadRadius: 2)] : []),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(hintText: widget.hintText, prefixIcon: widget.prefixIcon, suffixIcon: widget.suffixIcon),
          ),
        ),
      ],
    );
  }
}
