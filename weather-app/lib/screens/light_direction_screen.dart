import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/app_provider.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_container.dart';
import '../widgets/qweather_icon.dart';
import '../theme/neu_theme.dart';
import '../utils/i18n.dart';

class LightDirectionScreen extends StatefulWidget {
  const LightDirectionScreen({super.key});

  @override
  _LightDirectionScreenState createState() => _LightDirectionScreenState();
}

class _LightDirectionScreenState extends State<LightDirectionScreen> {
  // Center of the dial
  final double dialRadius = 120.0;
  final double knobRadius = 30.0;

  void _updateAngle(Offset localPosition, Size constraints) {
    final center = Offset(constraints.width / 2, constraints.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final angle = atan2(dy, dx);
    Provider.of<AppProvider>(context, listen: false).setLightAngle(angle);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final lang = provider.language;
    final angle = provider.lightAngle;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              CommonHeader(title: I18n.get('light_direction', lang)),
              const SizedBox(height: 48),
              Text(
                I18n.get('light_direction_desc', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NeuTheme.getSecondaryText(isDark),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 64),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final center = Offset(120, 120); // half of width
                    // Knob position
                    double knobX =
                        center.dx +
                        (dialRadius - knobRadius) * cos(angle) -
                        knobRadius;
                    double knobY =
                        center.dy +
                        (dialRadius - knobRadius) * sin(angle) -
                        knobRadius;

                    return GestureDetector(
                      onPanUpdate: (details) => _updateAngle(
                        details.localPosition,
                        const Size(240, 240),
                      ),
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          children: [
                            // The Track (Inner Shadow effect)
                            NeuContainer(
                              width: 240,
                              height: 240,
                              shape: BoxShape.circle,
                              isInner: false,
                            ),
                            // Central Preview
                            Positioned(
                              top: 70,
                              left: 70,
                              child: NeuContainer(
                                width: 100,
                                height: 100,
                                shape: BoxShape.circle,
                                child: Center(
                                  child: Icon(
                                    Icons.widgets_rounded,
                                    color: NeuTheme.getSecondaryText(isDark),
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            // Sun Knob
                            Positioned(
                              left: knobX,
                              top: knobY,
                              child: NeuContainer(
                                width: 60,
                                height: 60,
                                shape: BoxShape.circle,
                                child: const Center(
                                  child: QWeatherIcon(
                                    icon: '100',
                                    fill: true,
                                    color: Colors.orangeAccent,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
