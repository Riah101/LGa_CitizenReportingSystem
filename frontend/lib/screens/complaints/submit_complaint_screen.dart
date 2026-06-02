import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/complaint.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _mtaaCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();

  ComplaintCategory? _category;
  String? _selectedDistrict;
  String? _selectedRegion;
  bool _isAnonymous = false;
  bool _isUrgent = false;
  int _currentStep = 0;
  bool _isSubmitting = false;
  Complaint? _submittedComplaint;

  static const _regions = [
    'Dar es Salaam', 'Arusha', 'Mwanza', 'Dodoma', 'Morogoro',
    'Tanga', 'Kilimanjaro', 'Mbeya', 'Zanzibar', 'Pemba', 'Lindi',
    'Mara', 'Mtwara', 'Pwani', 'Ruvuma', 'Shinyanga', 'Singida',
    'Tabora', 'Kigoma', 'Iringa', 'Rukwa', 'Kagera',
  ];

  static const _categories = [
    (ComplaintCategory.infrastructure, Icons.construction_outlined, '🏗️'),
    (ComplaintCategory.water, Icons.water_drop_outlined, '💧'),
    (ComplaintCategory.electricity, Icons.bolt_outlined, '⚡'),
    (ComplaintCategory.health, Icons.local_hospital_outlined, '🏥'),
    (ComplaintCategory.education, Icons.school_outlined, '🎓'),
    (ComplaintCategory.security, Icons.security_outlined, '🛡️'),
    (ComplaintCategory.environment, Icons.eco_outlined, '🌿'),
    (ComplaintCategory.socialServices, Icons.people_outline, '👥'),
    (ComplaintCategory.corruption, Icons.gavel_outlined, '⚖️'),
    (ComplaintCategory.other, Icons.more_horiz_outlined, '📋'),
  ];

  String _getCategoryLabel(ComplaintCategory cat, AppLocalizations l) {
    switch (cat) {
      case ComplaintCategory.infrastructure: return l.catInfrastructure;
      case ComplaintCategory.water: return l.catWater;
      case ComplaintCategory.electricity: return l.catElectricity;
      case ComplaintCategory.health: return l.catHealth;
      case ComplaintCategory.education: return l.catEducation;
      case ComplaintCategory.security: return l.catSecurity;
      case ComplaintCategory.environment: return l.catEnvironment;
      case ComplaintCategory.socialServices: return l.catSocialServices;
      case ComplaintCategory.corruption: return l.catCorruption;
      case ComplaintCategory.other: return l.catOther;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      _showSnack(AppLocalizations.of(context).selectCategory);
      return;
    }

    setState(() => _isSubmitting = true);

    final user = context.read<AuthProvider>().currentUser!;
    final complaint = await context.read<ComplaintProvider>().submitComplaint(
          citizenId: user.id,
          citizenName: user.name,
          citizenPhone: user.phone,
          title: _titleCtrl.text,
          description: _descriptionCtrl.text,
          category: _category!,
          mtaa: _mtaaCtrl.text,
          ward: _wardCtrl.text,
          district: _selectedDistrict ?? '',
          region: _selectedRegion ?? '',
          isAnonymous: _isAnonymous,
          isUrgent: _isUrgent,
        );

    setState(() {
      _isSubmitting = false;
      _submittedComplaint = complaint;
      _currentStep = 3;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_submittedComplaint != null) {
      return _SuccessScreen(complaint: _submittedComplaint!, l: l);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.submitComplaint),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: AppTheme.divider,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
            minHeight: 3,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: IndexedStack(
          index: _currentStep,
          children: [
            _StepCategory(
              categories: _categories,
              selected: _category,
              onSelect: (c) => setState(() => _category = c),
              getLabelFn: (c) => _getCategoryLabel(c, l),
              l: l,
            ),
            _StepDetails(
              titleCtrl: _titleCtrl,
              descriptionCtrl: _descriptionCtrl,
              isUrgent: _isUrgent,
              isAnonymous: _isAnonymous,
              onUrgentChange: (v) => setState(() => _isUrgent = v),
              onAnonymousChange: (v) => setState(() => _isAnonymous = v),
              l: l,
            ),
            _StepLocation(
              mtaaCtrl: _mtaaCtrl,
              wardCtrl: _wardCtrl,
              selectedRegion: _selectedRegion,
              selectedDistrict: _selectedDistrict,
              regions: _regions,
              onRegionChange: (v) =>
                  setState(() => _selectedRegion = v),
              onDistrictChange: (v) =>
                  setState(() => _selectedDistrict = v),
              l: l,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(top: BorderSide(color: AppTheme.divider)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _currentStep--),
                  child: Text(l.back),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _submit();
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _currentStep < 2 ? l.next : l.submit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCategory extends StatelessWidget {
  final List<(ComplaintCategory, IconData, String)> categories;
  final ComplaintCategory? selected;
  final void Function(ComplaintCategory) onSelect;
  final String Function(ComplaintCategory) getLabelFn;
  final AppLocalizations l;

  const _StepCategory({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.getLabelFn,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.selectCategory,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            l.isSwahili
                ? 'Chagua aina ya lalamiko lako'
                : 'Choose the type of your complaint',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: categories
                .map((e) => _CategoryTile(
                      category: e.$1,
                      icon: e.$2,
                      emoji: e.$3,
                      label: getLabelFn(e.$1),
                      isSelected: selected == e.$1,
                      onTap: () => onSelect(e.$1),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ComplaintCategory category;
  final IconData icon;
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.icon,
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDetails extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  final bool isUrgent;
  final bool isAnonymous;
  final void Function(bool) onUrgentChange;
  final void Function(bool) onAnonymousChange;
  final AppLocalizations l;

  const _StepDetails({
    required this.titleCtrl,
    required this.descriptionCtrl,
    required this.isUrgent,
    required this.isAnonymous,
    required this.onUrgentChange,
    required this.onAnonymousChange,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.complaintDetails,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            l.isSwahili
                ? 'Elezea tatizo lako kwa undani'
                : 'Describe your issue in detail',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: titleCtrl,
            decoration: InputDecoration(
              labelText: l.complaintTitle,
              hintText: l.titleHint,
              prefixIcon: const Icon(Icons.title_outlined),
            ),
            maxLength: 100,
            validator: (v) => v?.isEmpty == true ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descriptionCtrl,
            decoration: InputDecoration(
              labelText: l.complaintDescription,
              hintText: l.descriptionHint,
              prefixIcon: const Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            maxLength: 1000,
            validator: (v) {
              if (v?.isEmpty == true) return l.fieldRequired;
              if ((v?.length ?? 0) < 20) {
                return l.isSwahili
                    ? 'Tafadhali elezea zaidi (herufi 20+)'
                    : 'Please provide more details (20+ characters)';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Photo attachment placeholder
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.attach_file_outlined),
            label: Text(l.addPhoto),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.divider),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Options
          _OptionSwitch(
            label: l.markUrgent,
            subtitle: l.isSwahili
                ? 'Inahitaji hatua ya haraka'
                : 'Requires immediate attention',
            value: isUrgent,
            onChanged: onUrgentChange,
            activeColor: AppTheme.statusEscalated,
            icon: Icons.priority_high_rounded,
          ),
          const SizedBox(height: 8),
          _OptionSwitch(
            label: l.submitAnonymously,
            subtitle: l.isSwahili
                ? 'Jina lako halitaonyeshwa'
                : 'Your name will not be shown',
            value: isAnonymous,
            onChanged: onAnonymousChange,
            activeColor: AppTheme.primaryGreen,
            icon: Icons.visibility_off_outlined,
          ),
        ],
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;
  final Color activeColor;
  final IconData icon;

  const _OptionSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value ? activeColor.withOpacity(0.08) : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? activeColor.withOpacity(0.3) : AppTheme.divider,
        ),
      ),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        secondary: Icon(icon, color: value ? activeColor : AppTheme.textSecondary),
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _StepLocation extends StatelessWidget {
  final TextEditingController mtaaCtrl;
  final TextEditingController wardCtrl;
  final String? selectedRegion;
  final String? selectedDistrict;
  final List<String> regions;
  final void Function(String?) onRegionChange;
  final void Function(String?) onDistrictChange;
  final AppLocalizations l;

  const _StepLocation({
    required this.mtaaCtrl,
    required this.wardCtrl,
    required this.selectedRegion,
    required this.selectedDistrict,
    required this.regions,
    required this.onRegionChange,
    required this.onDistrictChange,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.location,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            l.isSwahili
                ? 'Taja mahali ambapo tatizo liko'
                : 'Specify where the issue is located',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Escalation levels visual
          _LocationHierarchyHint(l: l),
          const SizedBox(height: 20),

          TextFormField(
            controller: mtaaCtrl,
            decoration: InputDecoration(
              labelText: l.mtaa,
              hintText: l.mtaaHint,
              prefixIcon: const Icon(Icons.home_outlined),
            ),
            validator: (v) => v?.isEmpty == true ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: wardCtrl,
            decoration: InputDecoration(
              labelText: l.ward,
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            validator: (v) => v?.isEmpty == true ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedRegion,
            decoration: InputDecoration(
              labelText: l.region,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            items: regions
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: onRegionChange,
            validator: (v) => v == null ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: l.district,
              prefixIcon: const Icon(Icons.account_balance_outlined),
            ),
            onChanged: (v) => onDistrictChange(v.isEmpty ? null : v),
          ),
        ],
      ),
    );
  }
}

class _LocationHierarchyHint extends StatelessWidget {
  final AppLocalizations l;
  const _LocationHierarchyHint({required this.l});

  @override
  Widget build(BuildContext context) {
    final levels = [
      ('Mtaa', AppTheme.levelMtaa, '7d'),
      ('Kata', AppTheme.levelWard, '14d'),
      ('Wilaya', AppTheme.levelDistrict, '21d'),
      ('Mkoa', AppTheme.levelRegion, '30d'),
      ('Taifa', AppTheme.levelNational, '∞'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.isSwahili
                ? '📋 Mfumo wa Kupandishwa'
                : '📋 Escalation System',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: levels
                .map((lvl) => Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: lvl.$2.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              lvl.$1[0],
                              style: TextStyle(
                                  color: lvl.$2,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(lvl.$1,
                            style: const TextStyle(fontSize: 9)),
                        Text(lvl.$3,
                            style: TextStyle(
                                fontSize: 9,
                                color: lvl.$2,
                                fontWeight: FontWeight.w600)),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final Complaint complaint;
  final AppLocalizations l;

  const _SuccessScreen({required this.complaint, required this.l});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primaryGreen, size: 52),
              ),
              const SizedBox(height: 24),
              Text(
                l.complaintSubmitted,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l.complaintSubmittedDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Tracking code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.08),
                      AppTheme.primaryGreenLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      l.saveTrackingCode,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      complaint.trackingCode,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: AppTheme.primaryGreen,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                  child: Text(l.done),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
