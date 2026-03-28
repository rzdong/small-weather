import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../utils/i18n.dart';
import 'forgot_pwd_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (_isSubmitting) {
      return;
    }

    final provider = context.read<AppProvider>();
    final lang = provider.language;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        context,
        lang == 'zh' ? '请输入邮箱和密码' : 'Please enter email and password',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await provider.login(email, password);
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (!success) {
      _showMessage(
        context,
        lang == 'zh'
            ? '登录失败，请检查邮箱或密码'
            : 'Login failed. Please check your email or password.',
      );
      return;
    }

    Navigator.pop(context);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeuButton(
                    width: 48,
                    height: 48,
                    radius: 24,
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: NeuTheme.getPrimaryText(isDark),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                I18n.get('login', lang),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Outfit',
                  color: NeuTheme.getPrimaryText(isDark),
                ),
              ),
              Text(
                lang == 'zh' ? "欢迎回来" : "Welcome Back",
                style: TextStyle(
                  fontSize: 16,
                  color: NeuTheme.getSecondaryText(isDark),
                ),
              ),
              const SizedBox(height: 64),
              NeuInput(
                icon: Icons.mail_rounded,
                hint: I18n.get('email', lang),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              NeuInput(
                icon: Icons.lock_rounded,
                hint: I18n.get('password', lang),
                obscureText: true,
                controller: _passwordController,
                onSubmitted: (_) => _handleLogin(context),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPwdScreen()),
                  ),
                  child: Text(
                    I18n.get('forgot_password', lang),
                    style: TextStyle(
                      color: NeuTheme.getPrimaryText(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              NeuButton(
                width: double.infinity,
                height: 64,
                radius: 32,
                onTap: _isSubmitting ? () {} : () => _handleLogin(context),
                child: Center(
                  child: Text(
                    _isSubmitting
                        ? (lang == 'zh' ? '登录中...' : 'Logging in...')
                        : I18n.get('login', lang),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeuTheme.getPrimaryText(isDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(
                    lang == 'zh'
                        ? '没有账号？去注册'
                        : "Don't have an account? Sign Up",
                    style: TextStyle(
                      color: NeuTheme.getSecondaryText(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
