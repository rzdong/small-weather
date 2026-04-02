import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../widgets/neu_container.dart';
import '../utils/i18n.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSendingCode = false;
  bool _isSubmitting = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSendCode() async {
    if (_isSendingCode || _countdownSeconds > 0) {
      return;
    }

    final provider = context.read<AppProvider>();
    final lang = provider.language;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage(lang == 'zh' ? '请输入邮箱地址' : 'Please enter your email');
      return;
    }

    setState(() => _isSendingCode = true);
    final message = await provider.sendRegisterCode(email);
    if (!mounted) {
      return;
    }
    setState(() => _isSendingCode = false);
    if ((message ?? '').toLowerCase().contains('sent') ||
        message == 'Verification code sent' ||
        message == '验证码已发送') {
      _startCountdown();
    }
    _showMessage(
      message ?? (lang == 'zh' ? '验证码已发送' : 'Verification code sent'),
    );
  }

  Future<void> _handleRegister() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<AppProvider>();
    final result = await provider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      code: _codeController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (result != null) {
      _showMessage(result);
      return;
    }

    Navigator.pop(context);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _countdownSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _countdownSeconds = 0);
        }
        return;
      }
      setState(() => _countdownSeconds -= 1);
    });
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
                I18n.get('sign_up', lang),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Outfit',
                  color: NeuTheme.getPrimaryText(isDark),
                ),
              ),
              Text(
                lang == 'zh' ? '创建你的账号' : 'Create your account',
                style: TextStyle(
                  fontSize: 16,
                  color: NeuTheme.getSecondaryText(isDark),
                ),
              ),
              const SizedBox(height: 48),
              NeuInput(
                icon: Icons.mail_rounded,
                hint: I18n.get('email', lang),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              NeuContainer(
                height: 64,
                width: double.infinity,
                radius: 32,
                isInner: false,
                padding: const EdgeInsets.only(left: 24, right: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: NeuTheme.getSecondaryText(isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        style: TextStyle(
                          color: NeuTheme.getPrimaryText(isDark),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: lang == 'zh'
                              ? '邮箱验证码'
                              : 'Email verification code',
                          hintStyle: TextStyle(
                            color: NeuTheme.getSecondaryText(isDark),
                          ),
                        ),
                      ),
                    ),
                    NeuButton(
                      width: 104,
                      height: 48,
                      radius: 24,
                      onTap: (_isSendingCode || _countdownSeconds > 0)
                          ? () {}
                          : _handleSendCode,
                      child: Center(
                        child: Text(
                          _isSendingCode
                              ? (lang == 'zh' ? '发送中' : 'Sending')
                              : _countdownSeconds > 0
                              ? '${_countdownSeconds}s'
                              : (lang == 'zh' ? '发送验证码' : 'Send Code'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: NeuTheme.getPrimaryText(isDark),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              NeuInput(
                icon: Icons.lock_rounded,
                hint: I18n.get('password', lang),
                obscureText: true,
                controller: _passwordController,
              ),
              const Spacer(),
              NeuButton(
                width: double.infinity,
                height: 64,
                radius: 32,
                onTap: _isSubmitting ? () {} : _handleRegister,
                child: Center(
                  child: Text(
                    _isSubmitting
                        ? (lang == 'zh' ? '注册中...' : 'Creating...')
                        : I18n.get('sign_up', lang),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeuTheme.getPrimaryText(isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
