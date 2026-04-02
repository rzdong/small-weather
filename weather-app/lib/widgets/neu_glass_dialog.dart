import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import 'neu_container.dart';
import 'neu_button.dart';

class NeuGlassDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const NeuGlassDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).isDarkMode;
    Color overlayColor = isDark
        ? const Color(0x801A222D)
        : const Color(0x80E0E6ED);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: overlayColor),
          ),
          Center(
            child: NeuContainer(
              width: 300,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: NeuTheme.getPrimaryText(isDark),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: NeuTheme.getPrimaryText(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: NeuTheme.getSecondaryText(isDark)),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      NeuButton(
                        width: 100,
                        height: 48,
                        radius: 24,
                        onTap: onCancel,
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: NeuTheme.getSecondaryText(isDark),
                            ),
                          ),
                        ),
                      ),
                      NeuButton(
                        width: 100,
                        height: 48,
                        radius: 24,
                        onTap: onConfirm,
                        child: Center(
                          child: Text(
                            'Confirm',
                            style: TextStyle(
                              color: NeuTheme.getPrimaryText(isDark),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
