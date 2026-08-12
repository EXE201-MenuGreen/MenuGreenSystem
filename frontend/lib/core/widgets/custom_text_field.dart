import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final bool readOnly;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode autovalidateMode;
  final ValueChanged<String>? onChanged;
  final GlobalKey<FormFieldState<String>>? formFieldKey;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.controller,
    this.readOnly = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.onChanged,
    this.formFieldKey,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: widget.formFieldKey,
          controller: widget.controller,
          readOnly: widget.readOnly,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          onChanged: widget.onChanged,
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.textLight, size: 20)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.progressBackground,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
