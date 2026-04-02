import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_button.dart';
import '../widgets/qweather_icon.dart';
import '../utils/i18n.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final lang = provider.language;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              CommonHeader(title: I18n.get('about', lang)),
              const SizedBox(height: 64),
              const QWeatherIcon(
                icon: '100',
                fill: true,
                size: 100,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 24),
              Text(
                "Pencil Weather",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: NeuTheme.getPrimaryText(isDark),
                ),
              ),
              Text(
                "Version 1.0.0",
                style: TextStyle(color: NeuTheme.getSecondaryText(isDark)),
              ),
              const Spacer(),
              NeuButton(
                radius: 32,
                height: 64,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'zh' ? '已经是最新版本' : 'You are up to date!',
                      ),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    lang == 'zh' ? '检查更新' : 'Check for Updates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NeuTheme.getPrimaryText(isDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
