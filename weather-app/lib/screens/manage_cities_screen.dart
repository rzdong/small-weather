import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_container.dart';
import '../utils/i18n.dart';

class ManageCitiesScreen extends StatefulWidget {
  const ManageCitiesScreen({super.key});

  @override
  _ManageCitiesScreenState createState() => _ManageCitiesScreenState();
}

class _ManageCitiesScreenState extends State<ManageCitiesScreen> {
  void _handleDeleteCity(
    BuildContext context,
    AppProvider provider,
    String cityId,
    String lang,
  ) {
    if (provider.userCities.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18n.get('last_location_cannot_delete', lang)),
        ),
      );
      return;
    }

    provider.deleteCity(cityId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final lang = provider.language;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: CommonHeader(title: I18n.get('location_settings', lang)),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                itemCount: provider.userCities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final city = provider.userCities[index];
                  return NeuContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: Colors.redAccent),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  city['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: NeuTheme.getPrimaryText(isDark),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        NeuButton(
                          width: 48,
                          height: 48,
                          radius: 24,
                          onTap: () {
                            _handleDeleteCity(
                              context,
                              provider,
                              city['id'].toString(),
                              lang,
                            );
                          },
                          child: Icon(Icons.delete_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
