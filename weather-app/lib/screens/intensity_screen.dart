import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../utils/i18n.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_container.dart';

class IntensityScreen extends StatelessWidget {
  const IntensityScreen({super.key});

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
              CommonHeader(title: I18n.get('3d_intensity', lang)),
              const SizedBox(height: 64),

              Text(
                I18n.get('3d_intensity_desc', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NeuTheme.getSecondaryText(isDark),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 64),

              // Preview element
              NeuContainer(
                width: 160,
                height: 160,
                radius: 80,
                shape: BoxShape.circle,
                child: Center(
                  child: Icon(
                    Icons.layers_rounded,
                    size: 64,
                    color: NeuTheme.getSecondaryText(isDark),
                  ),
                ),
              ),

              const SizedBox(height: 80),

              Slider(
                value: provider.shadowIntensity,
                min: 0.1,
                max: 2.0,
                activeColor: NeuTheme.getPrimaryText(isDark),
                inactiveColor: NeuTheme.getSecondaryText(isDark),
                onChanged: (val) => provider.setShadowIntensity(val),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    I18n.get('flat', lang),
                    style: TextStyle(color: NeuTheme.getSecondaryText(isDark)),
                  ),
                  Text(
                    I18n.get('deep', lang),
                    style: TextStyle(color: NeuTheme.getSecondaryText(isDark)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
