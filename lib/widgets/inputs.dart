import 'package:flutter/material.dart';
import '../core/theme.dart';

class InputField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const InputField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.caption(context, colors.textSecondary).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTheme.bodyMd(context, colors.textPrimary),
          cursorColor: colors.accentPrimary,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTheme.bodyMd(context, colors.textSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: colors.bgSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class TextArea extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;

  const TextArea({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.maxLines = 8,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.caption(context, colors.textSecondary).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          style: AppTheme.bodyMd(context, colors.textPrimary),
          cursorColor: colors.accentPrimary,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTheme.bodyMd(context, colors.textSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: colors.bgSurface,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
