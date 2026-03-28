import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_button.dart';
import '../widgets/qweather_icon.dart';
import 'package:intl/intl.dart';
import '../utils/i18n.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AppProvider>().fetchDailyForecast();
    });
  }

  static const double _forecastIconColumnWidth = 56;
  static const double _forecastTempColumnWidth = 88;

  String _buildWeekdayLabel(DateTime date, int index, String lang) {
    if (index == 0) {
      return I18n.get('today', lang);
    }

    if (index == 1) {
      return I18n.get('tomorrow', lang);
    }

    if (index == 2 && lang == 'zh') {
      return I18n.get('day_after_tomorrow', lang);
    }

    return DateFormat('EEEE', lang == 'zh' ? 'zh_CN' : 'en').format(date);
  }

  String _buildDateLabel(DateTime date, String lang) {
    if (lang == 'zh') {
      return DateFormat('M月 d日', 'zh_CN').format(date);
    }

    return DateFormat('MMM d', 'en').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final lang = provider.language;
    final daily = provider.dailyForecast;
    final isLoading = provider.isForecastLoading && daily.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: CommonHeader(title: I18n.get('forecast_7d', lang)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<AppProvider>().fetchDailyForecast(force: true),
                color: NeuTheme.getPrimaryText(isDark),
                backgroundColor: NeuTheme.getBg(isDark),
                child: isLoading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 220),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.all(24.0),
                        itemCount: daily.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final day = daily[index];
                          final date =
                              DateTime.tryParse(day['fxDate'] ?? '') ??
                              DateTime.now();
                          final weekDay = _buildWeekdayLabel(date, index, lang);
                          final tempMax = day['tempMax'] ?? '--';
                          final tempMin = day['tempMin'] ?? '--';
                          final text = day['textDay'] ?? '';
                          final iconCode = day['iconDay']?.toString() ?? '100';

                          return NeuButton(
                            height: 80,
                            radius: 40,
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          weekDay,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: NeuTheme.getPrimaryText(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _buildDateLabel(date, lang),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: NeuTheme.getSecondaryText(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: _forecastIconColumnWidth,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        QWeatherIcon(
                                          icon: iconCode,
                                          fill: true,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          text,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: NeuTheme.getSecondaryText(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 0),
                                  SizedBox(
                                    width: _forecastTempColumnWidth,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        "$tempMin° - $tempMax°",
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.visible,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: NeuTheme.getPrimaryText(
                                            isDark,
                                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}
