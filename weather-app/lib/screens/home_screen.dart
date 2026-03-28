import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_container.dart';
import '../widgets/qweather_icon.dart';
import '../utils/i18n.dart';
import 'forecast_screen.dart';
import 'settings_screen.dart';
import 'add_city_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _hourlyAxisGutter = 0;
  static const double _hourlyCardWidth = 76;
  static const double _hourlyCardGap = 12;
  static const double _hourlyChartHeight = 220;
  static const double _hourlyHeaderHeight = 40;
  static const double _hourlyFirstPointScreenOffset = 24;
  static const double _hourlyAnnotationWidth = 76;

  final GlobalKey _locationKey = GlobalKey();
  final ScrollController _hourlyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.currentWeather.isEmpty &&
          provider.selectedCityId.isNotEmpty) {
        provider.fetchWeather();
      }
    });
  }

  @override
  void dispose() {
    _hourlyScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.fetchWeather(forceRefresh: true);
  }

  List<_HourlyWeatherPoint> _buildHourlyData(
    List<dynamic> hourlyForecast,
    String lang,
  ) {
    final source = hourlyForecast.isNotEmpty
        ? hourlyForecast.take(24).toList()
        : List.generate(24, (index) => null);

    return List.generate(source.length, (index) {
      final hour = source[index];
      final fallbackTemp = 18 + (index % 5);
      final timeStr = hour != null
          ? (hour['fxTime'] as String?)?.substring(11, 16) ??
                '${index.toString().padLeft(2, '0')}:00'
          : '${index.toString().padLeft(2, '0')}:00';
      final label = index == 0 ? I18n.get('now', lang) : timeStr;
      final tempValue =
          num.tryParse('${hour?['temp'] ?? fallbackTemp}')?.toDouble() ??
          fallbackTemp.toDouble();

      final condition =
          hour?['text']?.toString() ??
          hour?['textDay']?.toString() ??
          I18n.get('sunny', lang);

      return _HourlyWeatherPoint(
        timeLabel: label,
        tempLabel: '${tempValue.round()}°',
        tempValue: tempValue,
        icon: hour?['icon']?.toString() ?? (index % 3 == 0 ? '101' : '100'),
        condition: condition,
      );
    });
  }

  void _showLocationDropdown(BuildContext context) {
    final RenderBox? renderBox =
        _locationKey.currentContext?.findRenderObject() as RenderBox?;
    final offset =
        renderBox?.localToGlobal(Offset.zero) ?? const Offset(24, 60);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Location',
      barrierColor: Colors.transparent, // Disable the dark mask
      pageBuilder: (ctx, anim1, anim2) {
        final provider = Provider.of<AppProvider>(ctx, listen: false);
        final isDark = provider.isDarkMode;
        final lang = provider.language;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Frosted glass background
            // GestureDetector(
            //   behavior: HitTestBehavior.opaque,
            //   onTap: () => Navigator.pop(ctx),
            //   child: BackdropFilter(
            //     filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            //     child: Container(
            //       color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
            //     ),
            //   ),
            // ),
            Positioned(
              top: offset.dy,
              left: offset.dx,
              width: 240,
              child: Material(
                type: MaterialType.transparency,
                child: NeuContainer(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  radius: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...provider.userCities.map((city) {
                        final isSelected =
                            city['id'] == provider.selectedCityId;
                        return InkWell(
                          onTap: () {
                            provider.selectCity(
                              city['id'] ?? '',
                              city['name'] ?? '',
                            );
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: isSelected
                                      ? const Color(0xFFFF7676)
                                      : NeuTheme.getSecondaryText(isDark),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  city['name'] ?? '',
                                  style: TextStyle(
                                    color: isSelected
                                        ? NeuTheme.getPrimaryText(isDark)
                                        : NeuTheme.getSecondaryText(isDark),
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: NeuTheme.getSecondaryText(
                          isDark,
                        ).withOpacity(0.2),
                      ),
                      // Add City
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddCityScreen(),
                            ),
                          );
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_rounded,
                                color: NeuTheme.getPrimaryText(isDark),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                I18n.get('add_new_city', lang),
                                style: TextStyle(
                                  color: NeuTheme.getPrimaryText(isDark),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final lang = provider.language;
    final now = provider.currentWeather['now'] as Map<String, dynamic>?;
    final currentWeatherIcon = now?['icon']?.toString() ?? '100';
    final hourlyData = _buildHourlyData(provider.hourlyForecast, lang);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header Map
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NeuButton(
                    key: _locationKey,
                    width: 200,
                    height: 48,
                    radius: 24,
                    onTap: () => _showLocationDropdown(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: NeuTheme.getPrimaryText(isDark),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.selectedCityName.isNotEmpty
                                  ? provider.selectedCityName
                                  : 'Select City',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: NeuTheme.getPrimaryText(isDark),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: NeuTheme.getPrimaryText(isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  NeuButton(
                    width: 48,
                    height: 48,
                    radius: 24,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: NeuTheme.getPrimaryText(isDark),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Master Component
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                displacement: 20,
                color: NeuTheme.getPrimaryText(isDark),
                backgroundColor: NeuTheme.getBg(isDark),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        provider.lastSyncTime != null
                            ? "${lang == 'zh' ? '最后更新' : 'Last sync'}: ${provider.lastSyncTime}"
                            : "",
                        style: TextStyle(
                          fontSize: 10,
                          color: NeuTheme.getSecondaryText(isDark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Weather Visual
                      NeuContainer(
                        width: 180,
                        height: 180,
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(20),
                        distance: 10,
                        blur: 20,
                        child: Center(
                          child: QWeatherIcon(
                            icon: currentWeatherIcon,
                            fill: true,
                            size: 112,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _AnimatedMetricText(
                        value: _parseMetricValue(now?['temp']),
                        suffix: '°',
                        duration: const Duration(milliseconds: 650),
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Outfit',
                          color: NeuTheme.getPrimaryText(isDark),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        provider.currentWeather['now']?['text'] ??
                            I18n.get('sunny', lang),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: NeuTheme.getSecondaryText(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMMM d, yyyy',
                          lang == 'zh' ? 'zh_CN' : 'en',
                        ).format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: NeuTheme.getSecondaryText(isDark),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: _hourlyChartHeight + _hourlyHeaderHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: _hourlyHeaderHeight,
                              left: 0,
                              right: 0,
                              child: _buildHourlyForecastSection(
                                context,
                                isDark: isDark,
                                lang: lang,
                                hourlyData: hourlyData,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 24,
                              right: 24,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox.shrink(),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ForecastScreen(),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            I18n.get('seven_days', lang),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: NeuTheme.getSecondaryText(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: NeuTheme.getSecondaryText(
                                              isDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Weather Details Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 0.8,
                                    child: _buildDetailCard(
                                      isDark,
                                      const Icon(Icons.air),
                                      I18n.get('wind', lang),
                                      value: _parseMetricValue(
                                        now?['windSpeed'],
                                      ),
                                      suffix: ' km/h',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 0.8,
                                    child: _buildDetailCard(
                                      isDark,
                                      const Icon(Icons.water_drop_rounded),
                                      I18n.get('humidity', lang),
                                      value: _parseMetricValue(
                                        now?['humidity'],
                                      ),
                                      suffix: '%',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 0.8,
                                    child: _buildDetailCard(
                                      isDark,
                                      const Icon(Icons.speed_rounded),
                                      I18n.get('pressure', lang),
                                      value: _parseMetricValue(
                                        now?['pressure'],
                                      ),
                                      suffix: ' hPa',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 0.8,
                                    child: _buildDetailCard(
                                      isDark,
                                      _AnimatedRotationIcon(
                                        angle:
                                            ((_parseMetricValue(
                                                      now?['wind360'],
                                                    ) ??
                                                    0) *
                                                math.pi) /
                                            180,
                                        child: const Icon(
                                          Icons.arrow_upward_rounded,
                                        ),
                                      ),
                                      I18n.get('wind_direction', lang),
                                      staticValue:
                                          now?['windDir']?.toString() ?? '--',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 0.8,
                                    child: _buildDetailCard(
                                      isDark,
                                      const Icon(Icons.thermostat_rounded),
                                      I18n.get('feels_like', lang),
                                      value: _parseMetricValue(
                                        now?['feelsLike'],
                                      ),
                                      suffix: '°',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 0.8,
                                    child: _buildDetailCard(
                                      isDark,
                                      const Icon(Icons.visibility_rounded),
                                      I18n.get('visibility', lang),
                                      value: _parseMetricValue(now?['vis']),
                                      suffix: ' km',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    bool isDark,
    Widget icon,
    String title, {
    double? value,
    String suffix = '',
    String? staticValue,
  }) {
    return NeuContainer(
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(
              color: NeuTheme.getPrimaryText(isDark),
              size: 28,
            ),
            child: icon,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: NeuTheme.getSecondaryText(isDark),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          if (staticValue != null)
            Text(
              staticValue,
              style: TextStyle(
                color: NeuTheme.getPrimaryText(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            )
          else
            _AnimatedMetricText(
              value: value,
              suffix: suffix,
              duration: const Duration(milliseconds: 650),
              style: TextStyle(
                color: NeuTheme.getPrimaryText(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  double? _parseMetricValue(dynamic raw) {
    if (raw == null) {
      return null;
    }

    return num.tryParse('$raw')?.toDouble();
  }

  Widget _buildHourlyForecastSection(
    BuildContext context, {
    required bool isDark,
    required String lang,
    required List<_HourlyWeatherPoint> hourlyData,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.max(
          constraints.maxWidth,
          _hourlyContentWidth(hourlyData.length),
        );
        final maxTemp = hourlyData
            .map((point) => point.tempValue)
            .reduce(math.max);
        final minTemp = hourlyData
            .map((point) => point.tempValue)
            .reduce(math.min);
        final chartMaxY = maxTemp + 3.2;
        final chartMinY = minTemp - 1.2;

        return SizedBox(
          height: _hourlyChartHeight,
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Stack(
              children: [
                Row(
                  children: [
                    SizedBox(width: _hourlyAxisGutter),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _hourlyScrollController,
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: SizedBox(
                          width: contentWidth,
                          child: Column(
                            children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, chartConstraints) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned.fill(
                                          child: LineChart(
                                            _buildHourlyChartData(
                                              isDark: isDark,
                                              hourlyData: hourlyData,
                                              chartWidth: contentWidth,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 500,
                                            ),
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                        IgnorePointer(
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              for (
                                                var i = 0;
                                                i < hourlyData.length;
                                                i++
                                              )
                                                Positioned(
                                                  left:
                                                      _hourlyPointX(i) -
                                                      (_hourlyAnnotationWidth /
                                                          2),
                                                  top:
                                                      _hourlyPointY(
                                                        tempValue: hourlyData[i]
                                                            .tempValue,
                                                        minY: chartMinY,
                                                        maxY: chartMaxY,
                                                        chartHeight:
                                                            chartConstraints
                                                                .maxHeight,
                                                      ) -
                                                      70,
                                                  width: _hourlyAnnotationWidth,
                                                  child: _buildHourlyAnnotation(
                                                    hourlyData[i],
                                                    isDark: isDark,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 28,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    for (var i = 0; i < hourlyData.length; i++)
                                      Positioned(
                                        left: _hourlyTimeLabelLeft(
                                          hourlyData[i].timeLabel,
                                          i,
                                        ),
                                        width: _hourlyTimeLabelWidth(
                                          hourlyData[i].timeLabel,
                                        ),
                                        child: Text(
                                          hourlyData[i].timeLabel,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: NeuTheme.getSecondaryText(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  LineChartData _buildHourlyChartData({
    required bool isDark,
    required List<_HourlyWeatherPoint> hourlyData,
    required double chartWidth,
  }) {
    final chartLineColor = QWeatherIcons.warmColor;
    final maxTemp = hourlyData.map((point) => point.tempValue).reduce(math.max);
    final minTemp = hourlyData.map((point) => point.tempValue).reduce(math.min);
    final maxY = maxTemp + 3.2;
    final minY = minTemp - 1.2;

    final spots = [
      for (var i = 0; i < hourlyData.length; i++)
        FlSpot(_hourlyPointX(i), hourlyData[i].tempValue),
    ];
    final lineBarData = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.28,
      color: chartLineColor,
      barWidth: 2,
      dashArray: [6, 4],
      isStrokeCapRound: true,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            chartLineColor.withValues(alpha: 0.24),
            chartLineColor.withValues(alpha: 0.02),
          ],
        ),
      ),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return _WeatherPointPainter(
            pointColor: chartLineColor,
            radius: 3.5,
            strokeWidth: 1.5,
            strokeColor: NeuTheme.getBg(isDark),
          );
        },
      ),
    );

    return LineChartData(
      minX: 0,
      maxX: chartWidth,
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData(
        top: false,
        bottom: true,
        left: false,
        right: false,
      ),
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(),
        rightTitles: AxisTitles(),
        topTitles: AxisTitles(),
        bottomTitles: AxisTitles(),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [lineBarData],
    );
  }

  Widget _buildHourlyAnnotation(
    _HourlyWeatherPoint point, {
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QWeatherIcon(icon: point.icon, fill: true, size: 18),
        const SizedBox(height: 8),
        Text(
          point.condition,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            height: 1.0,
            color: NeuTheme.getSecondaryText(isDark),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          point.tempLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: NeuTheme.getPrimaryText(isDark),
          ),
        ),
      ],
    );
  }

  double _hourlyContentWidth(int itemCount) {
    if (itemCount <= 0) {
      return 0;
    }

    return _hourlyChartContentWidth(itemCount);
  }

  double _hourlyChartContentWidth(int itemCount) {
    if (itemCount <= 0) {
      return 0;
    }

    return _hourlyPointX(itemCount - 1);
  }

  double _hourlyPointX(int index) {
    final slotExtent = _hourlyCardWidth + _hourlyCardGap;
    return _hourlyFirstPointScreenOffset + (index * slotExtent);
  }

  double _hourlyPointY({
    required double tempValue,
    required double minY,
    required double maxY,
    required double chartHeight,
  }) {
    final normalized = (maxY - tempValue) / (maxY - minY);
    return normalized * chartHeight;
  }

  double _hourlyTimeLabelLeft(String label, int index) {
    return _hourlyPointX(index) - (_hourlyTimeLabelWidth(label) / 2);
  }

  double _hourlyTimeLabelWidth(String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return painter.width + 4;
  }
}

class _HourlyWeatherPoint {
  const _HourlyWeatherPoint({
    required this.timeLabel,
    required this.tempLabel,
    required this.tempValue,
    required this.icon,
    required this.condition,
  });

  final String timeLabel;
  final String tempLabel;
  final double tempValue;
  final String icon;
  final String condition;
}

class _WeatherPointPainter extends FlDotPainter {
  const _WeatherPointPainter({
    required this.pointColor,
    required this.radius,
    required this.strokeWidth,
    required this.strokeColor,
  });

  final Color pointColor;
  final double radius;
  final double strokeWidth;
  final Color strokeColor;

  @override
  Color get mainColor => pointColor;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    if (strokeWidth != 0.0 && strokeColor.a != 0.0) {
      canvas.drawCircle(
        offsetInCanvas,
        radius + (strokeWidth / 2),
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.drawCircle(
      offsetInCanvas,
      radius,
      Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  Size getSize(FlSpot spot) => const Size(56, 58);

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => this;

  @override
  List<Object?> get props => [pointColor, radius, strokeWidth, strokeColor];
}

class _AnimatedMetricText extends StatefulWidget {
  const _AnimatedMetricText({
    required this.value,
    required this.suffix,
    required this.style,
    required this.duration,
  });

  final double? value;
  final String suffix;
  final TextStyle style;
  final Duration duration;

  @override
  State<_AnimatedMetricText> createState() => _AnimatedMetricTextState();
}

class _AnimatedMetricTextState extends State<_AnimatedMetricText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value ?? 0;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(() {
      final animation = _animation;
      if (!mounted || animation == null) {
        return;
      }
      setState(() {
        _currentValue = animation.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedMetricText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    final targetValue = widget.value;
    if (targetValue == null) {
      return;
    }

    if (oldWidget.value == null) {
      setState(() {
        _currentValue = targetValue;
        _animation = null;
      });
      return;
    }

    if ((targetValue - _currentValue).abs() < 0.001) {
      return;
    }

    _animation = Tween<double>(
      begin: _currentValue,
      end: targetValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value == null) {
      return Text('--', style: widget.style);
    }

    return Text(
      '${_currentValue.round()}${widget.suffix}',
      style: widget.style,
    );
  }
}

class _AnimatedRotationIcon extends StatefulWidget {
  const _AnimatedRotationIcon({required this.angle, required this.child});

  final double angle;
  final Widget child;

  @override
  State<_AnimatedRotationIcon> createState() => _AnimatedRotationIconState();
}

class _AnimatedRotationIconState extends State<_AnimatedRotationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _currentAngle = widget.angle;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _controller.addListener(() {
      final animation = _animation;
      if (!mounted || animation == null) {
        return;
      }
      setState(() {
        _currentAngle = animation.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedRotationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.angle - _currentAngle).abs() < 0.001) {
      return;
    }

    _animation = Tween<double>(
      begin: _currentAngle,
      end: widget.angle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(angle: _currentAngle, child: widget.child);
  }
}
