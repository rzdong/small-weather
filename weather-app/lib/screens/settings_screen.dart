import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_container.dart';
import '../utils/i18n.dart';
import 'language_screen.dart';
import 'light_direction_screen.dart';
import 'intensity_screen.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'manage_cities_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final provider = context.read<AppProvider>();
      if (provider.isLoggedIn) {
        provider.fetchProfile();
      }
    });
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
            // Fixed Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: CommonHeader(title: I18n.get('settings', lang)),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Profile Section
                    provider.isLoggedIn
                        ? NeuContainer(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                NeuContainer(
                                  width: 64,
                                  height: 64,
                                  shape: BoxShape.circle,
                                  child: provider.userAvatar.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            provider.userAvatar,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.person_rounded,
                                              size: 32,
                                              color: NeuTheme.getPrimaryText(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_rounded,
                                          size: 32,
                                          color: NeuTheme.getPrimaryText(
                                            isDark,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.userName.isNotEmpty
                                            ? provider.userName
                                            : "User",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: NeuTheme.getPrimaryText(
                                            isDark,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        provider.userEmail,
                                        style: TextStyle(
                                          color: NeuTheme.getSecondaryText(
                                            isDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                NeuButton(
                                  width: 48,
                                  height: 48,
                                  radius: 24,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfileScreen(),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: NeuTheme.getPrimaryText(isDark),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : NeuContainer(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lang == 'zh'
                                        ? '登录账号以同步你的设置'
                                        : 'Log in to sync your settings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: NeuTheme.getPrimaryText(isDark),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                NeuButton(
                                  width: 64,
                                  height: 64,
                                  radius: 32,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      I18n.get('login', lang),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: NeuTheme.getPrimaryText(isDark),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 32),

                    Text(
                      lang == 'zh' ? '选项' : 'Preferences',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: NeuTheme.getPrimaryText(isDark),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preferences List
                    NeuContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildSettingsRow(
                            context: context,
                            icon: Icons.dark_mode_rounded,
                            title: I18n.get('dark_mode', lang),
                            action: Switch(
                              value: isDark,
                              onChanged: (val) => provider.toggleDarkMode(val),
                              activeThumbColor: Colors.greenAccent,
                              activeTrackColor: isDark
                                  ? Colors.grey[600]
                                  : Colors.white70,
                              inactiveThumbColor: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              inactiveTrackColor: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                            ),
                          ),
                          Divider(
                            height: 32,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),

                          _buildSettingsRow(
                            context: context,
                            icon: Icons.location_on_rounded,
                            title: I18n.get('location_settings', lang),
                            action: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageCitiesScreen(),
                              ),
                            ),
                          ),
                          Divider(
                            height: 32,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),

                          // _buildSettingsRow(
                          //   context: context,
                          //   icon: Icons.notifications_rounded,
                          //   title: I18n.get('notifications', lang),
                          //   action: Switch(
                          //     value: _notificationsEnabled,
                          //     onChanged: (val) =>
                          //         setState(() => _notificationsEnabled = val),
                          //     activeThumbColor: Colors.greenAccent,
                          //     activeTrackColor: isDark
                          //         ? Colors.grey[600]
                          //         : Colors.grey[200],
                          //     inactiveThumbColor: isDark
                          //         ? Colors.grey[400]
                          //         : Colors.grey[600],
                          //     inactiveTrackColor: isDark
                          //         ? Colors.grey[700]
                          //         : Colors.grey[300],
                          //   ),
                          // ),
                          // Divider(
                          //   height: 32,
                          //   color: isDark ? Colors.white10 : Colors.black12,
                          // ),
                          _buildSettingsRow(
                            context: context,
                            icon: Icons.language_rounded,
                            title: I18n.get('language', lang),
                            action: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LanguageScreen(),
                              ),
                            ),
                          ),
                          Divider(
                            height: 32,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),

                          _buildSettingsRow(
                            context: context,
                            icon: Icons.highlight_rounded,
                            title: I18n.get('light_direction', lang),
                            action: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LightDirectionScreen(),
                              ),
                            ),
                          ),
                          Divider(
                            height: 32,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),

                          _buildSettingsRow(
                            context: context,
                            icon: Icons.layers_rounded,
                            title: I18n.get('3d_intensity', lang),
                            action: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IntensityScreen(),
                              ),
                            ),
                          ),
                          Divider(
                            height: 32,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),

                          _buildSettingsRow(
                            context: context,
                            icon: Icons.info_rounded,
                            title: I18n.get('about', lang),
                            action: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AboutScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (provider.isLoggedIn) ...[
                      const SizedBox(height: 32),
                      NeuButton(
                        width: double.infinity,
                        height: 64,
                        onTap: () => provider.logout(),
                        child: Center(
                          child: Text(
                            I18n.get('log_out', lang),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget action,
    VoidCallback? onTap,
  }) {
    final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                NeuContainer(
                  width: 40,
                  height: 40,
                  shape: BoxShape.circle,
                  child: Icon(
                    icon,
                    color: NeuTheme.getPrimaryText(isDark),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeuTheme.getPrimaryText(isDark),
                  ),
                ),
              ],
            ),
            action,
          ],
        ),
      ),
    );
  }
}
