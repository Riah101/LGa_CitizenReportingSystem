import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/tanzania_locations.dart';
import '../dashboard/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+255');
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _mtaaCtrl = TextEditingController();
  String? _selectedWard;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _currentStep = 0;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      password: _passwordCtrl.text,
      nationalId: _nationalIdCtrl.text.isEmpty ? null : _nationalIdCtrl.text,
      mtaa: _mtaaCtrl.text.isEmpty ? null : _mtaaCtrl.text,
      ward: _selectedWard,
      district: 'Kinondoni',
      region: 'Dar es Salaam',
    );
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.createAccount),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            // Validate only the fields relevant to the current step
            if (_currentStep == 0) {
              if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).fieldRequired),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              setState(() => _currentStep++);
            } else if (_currentStep == 1) {
              setState(() => _currentStep++);
            } else {
              _register();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: isLoading ? null : details.onStepContinue,
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_currentStep == 2 ? l.register : l.next),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: Text(l.back),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // Step 1: Personal Info
            Step(
              title: Text(
                  l.isSwahili ? 'Taarifa Binafsi' : 'Personal Information'),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: l.fullName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v?.isEmpty == true ? l.fieldRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l.phoneNumber,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (v) =>
                        v?.isEmpty == true ? l.fieldRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nationalIdCtrl,
                    decoration: InputDecoration(
                      labelText: '${l.nationalId} (${l.isSwahili ? "Hiari" : "Optional"})',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                ],
              ),
            ),

            // Step 2: Location
            Step(
              title: Text(l.isSwahili ? 'Eneo Lako' : 'Your Location'),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  // Fixed region
                  _LockedField(label: l.region, value: 'Dar es Salaam'),
                  const SizedBox(height: 12),
                  // Fixed district
                  _LockedField(label: l.district, value: 'Kinondoni'),
                  const SizedBox(height: 12),
                  // Ward dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedWard,
                    decoration: InputDecoration(
                      labelText: l.ward,
                      prefixIcon: const Icon(Icons.map_outlined),
                    ),
                    items: TanzaniaLocations.kinondoniWards
                        .map((w) =>
                            DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedWard = v),
                  ),
                  const SizedBox(height: 12),
                  // Mtaa free text
                  TextFormField(
                    controller: _mtaaCtrl,
                    decoration: InputDecoration(
                      labelText: l.mtaa,
                      prefixIcon: const Icon(Icons.home_outlined),
                      hintText: l.mtaaHint,
                    ),
                  ),
                ],
              ),
            ),

            // Step 3: Security
            Step(
              title: Text(l.isSwahili ? 'Usalama' : 'Security'),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
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
                      if (v.length < 6) return l.passwordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: l.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordCtrl.text) {
                        return l.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedField extends StatelessWidget {
  final String label;
  final String value;
  const _LockedField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
