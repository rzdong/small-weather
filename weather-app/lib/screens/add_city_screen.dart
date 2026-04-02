import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../widgets/neu_loader.dart';
import '../utils/i18n.dart';

class AddCityScreen extends StatefulWidget {
  const AddCityScreen({super.key});

  @override
  _AddCityScreenState createState() => _AddCityScreenState();
}

class _AddCityScreenState extends State<AddCityScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).clearSearchResults();
    });
  }

  void _onSearch() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.searchCity(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;
    final lang = provider.language;
    final results = provider.searchResults;
    final isSearching = provider.isSearching;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              CommonHeader(title: I18n.get('add_new_city', lang)),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: NeuInput(
                      controller: _searchController,
                      icon: Icons.search_rounded,
                      hint: I18n.get('search_city', lang),
                      onSubmitted: (_) => _onSearch(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  NeuButton(
                    width: 60,
                    height: 56,
                    radius: 16,
                    onTap: _onSearch,
                    child: Icon(Icons.search_rounded, color: NeuTheme.getPrimaryText(isDark)),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              if (isSearching)
                Expanded(child: Center(child: NeuLoader()))
              else if (results.isEmpty && _searchController.text.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      I18n.get('no_results', lang),
                      style: TextStyle(color: NeuTheme.getSecondaryText(isDark)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final city = results[index];
                      final name = city['name'] ?? '';
                      final adm2 = city['adm2'] ?? '';
                      final adm1 = city['adm1'] ?? '';
                      
                      return NeuButton(
                        height: 72,
                        radius: 36,
                        onTap: () async {
                          await provider.addAndSelectCity(city);
                          if (mounted) Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: NeuTheme.getPrimaryText(isDark),
                                      ),
                                    ),
                                    Text(
                                      "$adm2, $adm1",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: NeuTheme.getSecondaryText(isDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.add_rounded,
                                color: NeuTheme.getPrimaryText(isDark),
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

class NeuContainerWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const NeuContainerWrapper({
    super.key,
    required this.child,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: onTap, child: child);
}
