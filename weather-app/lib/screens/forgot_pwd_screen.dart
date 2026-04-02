import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';
import '../widgets/common_header.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../widgets/neu_container.dart';
import '../utils/i18n.dart';

class ForgotPwdScreen extends StatefulWidget {
  const ForgotPwdScreen({super.key});

  @override
  State<ForgotPwdScreen> createState() => _ForgotPwdScreenState();
}

class _ForgotPwdScreenState extends State<ForgotPwdScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _isResetting = false;
  bool _isCodeVerified = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendCode() async {
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
    final message = await provider.sendResetPasswordCode(email);
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

  Future<void> _verifyCode() async {
    if (_isVerifyingCode) {
      return;
    }

    final provider = context.read<AppProvider>();
    final lang = provider.language;
    setState(() => _isVerifyingCode = true);
    final error = await provider.verifyResetPasswordCode(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isVerifyingCode = false;
      _isCodeVerified = error == null;
    });
    _showMessage(
      error ??
          (lang == 'zh'
              ? '验证码正确，请设置新密码'
              : 'Code verified. Please set a new password.'),
    );
  }

  Future<void> _resetPassword() async {
    if (_isResetting) {
      return;
    }

    final provider = context.read<AppProvider>();
    final lang = provider.language;

    if (_passwordController.text != _confirmController.text) {
      _showMessage(lang == 'zh' ? '两次输入的密码不一致' : 'Passwords do not match');
      return;
    }

    setState(() => _isResetting = true);
    final error = await provider.resetPassword(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isResetting = false);

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage(lang == 'zh' ? '密码已重置，请登录' : 'Password reset. Please log in.');
    Navigator.pop(context);
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
              CommonHeader(title: I18n.get('reset_password', lang)),
              const SizedBox(height: 32),
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
                          hintText: lang == 'zh' ? "验证码" : "Verification Code",
                          hintStyle: TextStyle(
                            color: NeuTheme.getSecondaryText(isDark),
                          ),
                        ),
                      ),
                    ),
                    NeuButton(
                      width: 96,
                      height: 48,
                      radius: 24,
                      onTap: (_isSendingCode || _countdownSeconds > 0)
                          ? () {}
                          : _sendCode,
                      child: Center(
                        child: Text(
                          _isSendingCode
                              ? (lang == 'zh' ? "发送中" : "Sending")
                              : _countdownSeconds > 0
                              ? '${_countdownSeconds}s'
                              : (lang == 'zh' ? "发送验证码" : "Send Code"),
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
              const SizedBox(height: 16),
              NeuButton(
                width: double.infinity,
                height: 56,
                radius: 28,
                onTap: _verifyCode,
                child: Center(
                  child: Text(
                    _isVerifyingCode
                        ? (lang == 'zh' ? '验证中...' : 'Verifying...')
                        : (lang == 'zh' ? '验证验证码' : 'Verify Code'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: NeuTheme.getPrimaryText(isDark),
                    ),
                  ),
                ),
              ),
              if (_isCodeVerified) ...[
                const SizedBox(height: 24),
                NeuInput(
                  icon: Icons.lock_rounded,
                  hint: lang == 'zh' ? "新密码" : "New Password",
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 24),
                NeuInput(
                  icon: Icons.lock_reset_rounded,
                  hint: I18n.get('confirm_password', lang),
                  obscureText: true,
                  controller: _confirmController,
                ),
              ],
              const Spacer(),
              NeuButton(
                width: double.infinity,
                height: 64,
                radius: 32,
                onTap: _isCodeVerified ? _resetPassword : () {},
                child: Center(
                  child: Text(
                    _isResetting
                        ? (lang == 'zh' ? "提交中..." : "Submitting...")
                        : (lang == 'zh' ? "确认" : "Confirm"),
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
