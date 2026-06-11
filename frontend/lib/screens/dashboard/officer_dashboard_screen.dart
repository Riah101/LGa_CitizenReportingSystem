import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/complaint.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/stat_card.dart';
import '../complaints/complaint_detail_screen.dart';

/// Officer Dashboard — shown to ward/district/region/national officers
class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() =>
      _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  GovernmentLevel? _filterLevel;
  ComplaintStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = context.watch<AuthProvider>().currentUser!;
    final provider = context.watch<ComplaintProvider>();
    final stats = provider.stats;

    // Officer sees complaints at their assigned level
    final assignedLevel = _officerLevel(user.role);
    var complaints = assignedLevel != null
        ? provider.complaintsForLevel(assignedLevel)
        : provider.complaints;

    if (_filterStatus != null) {
      complaints =
          complaints.where((c) => c.status == _filterStatus).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.isSwahili ? 'Dashibodi ya Afisa' : 'Officer Dashboard'),
            Text(
              user.roleLabel,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.checkAndEscalate(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Jurisdiction info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.domain_rounded,
                            color: AppTheme.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.isSwahili
                                ? 'Eneo lako: ${user.ward ?? user.district ?? user.region ?? "Taifa"}'
                                : 'Your jurisdiction: ${user.ward ?? user.district ?? user.region ?? "National"}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryGreenDark,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                        label: l.totalComplaints,
                        value: complaints.length.toString(),
                        icon: Icons.campaign_outlined,
                        color: AppTheme.primaryGreen,
                      ),
                      StatCard(
                        label: l.pendingComplaints,
                        value: complaints
                            .where((c) => c.status == ComplaintStatus.pending)
                            .length
                            .toString(),
                        icon: Icons.hourglass_empty_rounded,
                        color: AppTheme.statusPending,
                      ),
                      StatCard(
                        label: l.escalatedComplaints,
                        value: complaints
                            .where(
                                (c) => c.status == ComplaintStatus.escalated)
                            .length
                            .toString(),
                        icon: Icons.arrow_upward_rounded,
                        color: AppTheme.statusEscalated,
                      ),
                      StatCard(
                        label: l.resolvedComplaints,
                        value: complaints
                            .where((c) => c.status == ComplaintStatus.resolved)
                            .length
                            .toString(),
                        icon: Icons.check_circle_outline,
                        color: AppTheme.statusResolved,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: l.all,
                          selected: _filterStatus == null,
                          onTap: () =>
                              setState(() => _filterStatus = null),
                        ),
                        ...ComplaintStatus.values.map((s) => _FilterChip(
                              label: _statusLabel(s, l),
                              selected: _filterStatus == s,
                              color: AppTheme.statusColor(s.name
                                  .replaceAllMapped(RegExp(r'[A-Z]'),
                                      (m) => '_${m.group(0)!.toLowerCase()}')),
                              onTap: () =>
                                  setState(() => _filterStatus = s),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Complaints list
                  if (complaints.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          l.noComplaintsYet,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...complaints.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OfficerComplaintCard(
                            complaint: c,
                            l: l,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ComplaintDetailScreen(complaint: c),
                              ),
                            ),
                            onMarkInProgress: () => _confirmAction(
                              title: l.confirmMarkInProgress,
                              message: '"${c.title}"',
                              action: () => context
                                  .read<ComplaintProvider>()
                                  .updateStatus(c.id, ComplaintStatus.inProgress),
                              successMessage: l.markedInProgress,
                            ),
                            onResolve: () => _confirmAction(
                              title: l.confirmResolve,
                              message: '"${c.title}"',
                              action: () => context
                                  .read<ComplaintProvider>()
                                  .updateStatus(c.id, ComplaintStatus.resolved),
                              successMessage: l.markedResolved,
                            ),
                            onEscalate: () => _confirmAction(
                              title: l.confirmEscalate,
                              message: '"${c.title}"',
                              reasonLabel: l.escalateReason,
                              action: () => context
                                  .read<ComplaintProvider>()
                                  .manualEscalate(
                                    c.id,
                                    l.isSwahili
                                        ? 'Imepandishwa na afisa'
                                        : 'Manually escalated by officer',
                                  ),
                              successMessage: l.escalatedSuccess,
                            ),
                          ),
                        )),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  GovernmentLevel? _officerLevel(UserRole role) {
    switch (role) {
      case UserRole.mtaaOfficer: return GovernmentLevel.mtaa;
      case UserRole.wardOfficer: return GovernmentLevel.ward;
      case UserRole.districtOfficer: return GovernmentLevel.district;
      case UserRole.regionOfficer: return GovernmentLevel.region;
      case UserRole.nationalOfficer: return GovernmentLevel.national;
      default: return null;
    }
  }

  String _statusLabel(ComplaintStatus s, AppLocalizations l) {
    switch (s) {
      case ComplaintStatus.pending: return l.statusPending;
      case ComplaintStatus.inProgress: return l.statusInProgress;
      case ComplaintStatus.escalated: return l.statusEscalated;
      case ComplaintStatus.resolved: return l.statusResolved;
      case ComplaintStatus.closed: return l.statusClosed;
    }
  }

  void _showFilterSheet() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.filterByStatus,
                    style: Theme.of(ctx).textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    setState(() => _filterStatus = null);
                    Navigator.pop(ctx);
                  },
                  child: Text(l.clearFilter),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ComplaintStatus.values.map((s) {
                final selected = _filterStatus == s;
                final color = AppTheme.statusColor(s.name
                    .replaceAllMapped(RegExp(r'[A-Z]'),
                        (m) => '_${m.group(0)!.toLowerCase()}'));
                return FilterChip(
                  label: Text(_statusLabel(s, l)),
                  selected: selected,
                  selectedColor: color.withOpacity(0.2),
                  checkmarkColor: color,
                  side: BorderSide(color: selected ? color : AppTheme.divider),
                  onSelected: (_) {
                    setState(() => _filterStatus = s);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required Future<void> Function() action,
    required String successMessage,
    String? reasonLabel,
  }) async {
    final l = AppLocalizations.of(context);
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (reasonLabel != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: reasonLabel,
                  hintText: l.escalateReasonHint,
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? c : AppTheme.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OfficerComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final AppLocalizations l;
  final VoidCallback onTap;
  final VoidCallback onMarkInProgress;
  final VoidCallback onResolve;
  final VoidCallback onEscalate;

  const _OfficerComplaintCard({
    required this.complaint,
    required this.l,
    required this.onTap,
    required this.onMarkInProgress,
    required this.onResolve,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ComplaintCard(complaint: complaint, onTap: onTap),
        // Quick action buttons for officer
        if (complaint.status != ComplaintStatus.resolved &&
            complaint.status != ComplaintStatus.closed)
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (complaint.status == ComplaintStatus.pending)
                  Expanded(
                    child: _ActionBtn(
                      label: l.isSwahili ? 'Shughulikia' : 'Mark In Progress',
                      color: AppTheme.statusInProgress,
                      icon: Icons.play_arrow_rounded,
                      onTap: onMarkInProgress,
                    ),
                  ),
                if (complaint.status == ComplaintStatus.inProgress) ...[
                  Expanded(
                    child: _ActionBtn(
                      label: l.isSwahili ? 'Suluhisha' : 'Resolve',
                      color: AppTheme.statusResolved,
                      icon: Icons.check_rounded,
                      onTap: onResolve,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: l.isSwahili ? 'Pandisha' : 'Escalate',
                      color: AppTheme.statusEscalated,
                      icon: Icons.arrow_upward_rounded,
                      onTap: onEscalate,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
