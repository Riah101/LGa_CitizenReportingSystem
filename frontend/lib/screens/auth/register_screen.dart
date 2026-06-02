import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
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
  final _wardCtrl = TextEditingController();
  String? _selectedDistrict;
  String? _selectedRegion;

  bool _obscurePassword = true;
  int _currentStep = 0;

  static const regions = [
    'Dar es Salaam',
    'Arusha',
    'Mwanza',
    'Dodoma',
    'Morogoro',
    'Tanga',
    'Kilimanjaro',
    'Mbeya',
    'Zanzibar',
    'Pemba',
  ];

  static const districts = {
    'Dar es Salaam': ['Ilala', 'Kinondoni', 'Temeke', 'Ubungo', 'Kigamboni'],
    'Arusha': ['Arusha City', 'Arusha Rural', 'Monduli', 'Arumeru'],
    'Mwanza': ['Nyamagana', 'Ilemela', 'Magu', 'Kwimba'],
    'Dodoma': ['Dodoma Urban', 'Dodoma Rural', 'Kongwa', 'Chamwino'],
  };

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      password: _passwordCtrl.text,
      nationalId: _nationalIdCtrl.text.isEmpty ? null : _nationalIdCtrl.text,
      mtaa: _mtaaCtrl.text.isEmpty ? null : _mtaaCtrl.text,
      ward: _wardCtrl.text.isEmpty ? null : _wardCtrl.text,
      district: _selectedDistrict,
      region: _selectedRegion,
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
            if (_currentStep < 2) {
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
                  TextFormField(
                    controller: _mtaaCtrl,
                    decoration: InputDecoration(
                      labelText: l.mtaa,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      hintText: l.mtaaHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wardCtrl,
                    decoration: InputDecoration(
                      labelText: l.ward,
                      prefixIcon: const Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    decoration: InputDecoration(
                      labelText: l.region,
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    items: regions
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedRegion = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    decoration: InputDecoration(
                      labelText: l.district,
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                    ),
                    items: (districts[_selectedRegion] ?? [])
                        .map((d) =>
                            DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedDistrict = v),
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
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (v != _passwordCtrl.text)
                        return l.passwordsDoNotMatch;
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
