import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import 'neu_button.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const CommonHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NeuButton(
          width: 48,
          height: 48,
          radius: 24,
          onTap: onBack ?? () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: NeuTheme.getPrimaryText(isDark),
            size: 20,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
            color: NeuTheme.getPrimaryText(isDark),
          ),
        ),
        const SizedBox(width: 48), // Placeholder to balance back button
      ],
    );
  }
}
