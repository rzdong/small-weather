import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_button.dart';
import '../utils/i18n.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              CommonHeader(title: I18n.get('select_language', provider.language)),
              const SizedBox(height: 32),

              _buildLangOption(context, isDark, provider, "English", "en"),
              const SizedBox(height: 16),
              _buildLangOption(context, isDark, provider, "中文 (Chinese)", "zh"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangOption(
    BuildContext context,
    bool isDark,
    AppProvider provider,
    String title,
    String code,
  ) {
    bool isSelected = provider.language == code;
    return NeuButton(
      height: 64,
      radius: 32,
      onTap: () => provider.setLanguage(code),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? NeuTheme.getPrimaryText(isDark)
                    : NeuTheme.getSecondaryText(isDark),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: NeuTheme.getPrimaryText(isDark)),
          ],
        ),
      ),
    );
  }
}
