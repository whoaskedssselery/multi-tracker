import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.label,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.enabled = true,
    this.monospace = false,
    this.inputFormatters,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final bool enabled;
  final bool monospace;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autofocus,
      enabled: enabled,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: monospace
          ? const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 15)
          : theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: IconTheme(
                  data: const IconThemeData(color: AppColors.text3, size: 18),
                  child: prefixIcon!,
                ),
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(minWidth: 44)
            : null,
      ),
    );
  }
}
