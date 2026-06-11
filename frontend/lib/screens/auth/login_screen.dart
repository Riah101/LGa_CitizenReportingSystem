import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/app_theme.dart';
import '../dashboard/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+255');
  final _passwordCtrl = TextEditingController(text: '123456');
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_phoneCtrl.text, _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.loginError ?? AppLocalizations.of(context).loginFailed),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showForgotPassword() {
    final l = AppLocalizations.of(context);
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.forgotPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.forgotPasswordBody,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    )),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.phoneNumber,
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: '+255 7XX XXX XXX',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.resetCodeSent),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l.sendResetCode),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLoading = context.watch<AuthProvider>().isLoading;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LanguageToggle(provider: localeProvider),
                ],
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreenLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.appName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        l.appTagline,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Text(
                l.login,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l.isSwahili
                    ? 'Karibu tena! Ingia kwenye akaunti yako'
                    : 'Welcome back! Sign in to your account',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l.phoneNumber,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        hintText: '+255 7XX XXX XXX',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l.fieldRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l.fieldRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPassword,
                        child: Text(l.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l.login),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Demo hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.primaryGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      l.isSwahili
                          ? 'Demo: Weka nambari yoyote & nenosiri lolote'
                          : 'Demo: Enter any phone & password to continue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryGreenDark,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.dontHaveAccount,
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: Text(l.register),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final LocaleProvider provider;
  const _LanguageToggle({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: provider.toggleLocale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.isSwahili ? '🇹🇿' : '🇬🇧',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              provider.isSwahili ? 'Swahili' : 'English',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.swap_horiz, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
