import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import 'neu_container.dart';

class NeuInput extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Function(String)? onSubmitted;
  final bool readOnly;

  const NeuInput({
    super.key,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.onSubmitted,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;

    return NeuContainer(
      height: 64,
      width: double.infinity,
      radius: 32,
      isInner: false, // Use the simulated inner shadow logic
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: NeuTheme.getSecondaryText(isDark), size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                readOnly: readOnly,
                keyboardType: keyboardType,
                onSubmitted: onSubmitted,
                cursorColor: NeuTheme.getPrimaryText(isDark),
                style: TextStyle(
                  color: NeuTheme.getPrimaryText(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: NeuTheme.getSecondaryText(
                      isDark,
                    ).withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
