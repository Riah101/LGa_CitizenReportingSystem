import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/complaint.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/escalation_timeline.dart';
import '../../widgets/stat_card.dart';
import '../complaints/complaint_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final complaintProvider = context.watch<ComplaintProvider>();
    final stats = complaintProvider.stats;
    final recent = complaintProvider.complaints.take(3).toList();
    final user = auth.currentUser;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l.goodMorning
        : hour < 17
            ? l.goodAfternoon
            : l.goodEvening;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () => complaintProvider.checkAndEscalate(),
        color: AppTheme.primaryGreen,
        child: CustomScrollView(
          slivers: [
            // App Bar Header
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreenDark,
                        AppTheme.primaryGreen,
                        Color(0xFF2ECC8A),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting,',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    user?.name.split(' ').first ?? l.welcome,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Mtaa location badge
                          if (user?.mtaa != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user!.mtaa}, ${user.ward}, ${user.district}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    Text(l.quickStats,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
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
                          value: stats['total'].toString(),
                          icon: Icons.campaign_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                        StatCard(
                          label: l.pendingComplaints,
                          value: stats['pending'].toString(),
                          icon: Icons.hourglass_empty_rounded,
                          color: AppTheme.statusPending,
                        ),
                        StatCard(
                          label: l.escalatedComplaints,
                          value: stats['escalated'].toString(),
                          icon: Icons.arrow_upward_rounded,
                          color: AppTheme.statusEscalated,
                        ),
                        StatCard(
                          label: l.resolvedComplaints,
                          value: stats['resolved'].toString(),
                          icon: Icons.check_circle_outline,
                          color: AppTheme.statusResolved,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Escalation Overview
                    _EscalationOverview(),

                    const SizedBox(height: 24),

                    // Recent Complaints
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.recentComplaints,
                            style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                          onPressed: () {},
                          child: Text(l.viewAll),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (recent.isEmpty)
                      _EmptyState(l: l)
                    else
                      ...recent.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ComplaintCard(
                              complaint: c,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ComplaintDetailScreen(complaint: c),
                                ),
                              ),
                            ),
                          )),

                    const SizedBox(height: 100), // FAB padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EscalationOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final complaints = context.watch<ComplaintProvider>().complaints;
    final dueForEscalation = complaints
        .where((c) =>
            c.daysUntilEscalation() <= 2 &&
            c.daysUntilEscalation() >= 0 &&
            c.status != ComplaintStatus.resolved &&
            c.status != ComplaintStatus.closed)
        .length;

    if (dueForEscalation == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.statusEscalated.withOpacity(0.1),
            AppTheme.statusPending.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.statusEscalated.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.statusEscalated.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppTheme.statusEscalated, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.isSwahili
                      ? '$dueForEscalation malalamiko yatakapandishwa hivi karibuni'
                      : '$dueForEscalation complaint${dueForEscalation > 1 ? 's' : ''} due for escalation',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  l.isSwahili
                      ? 'Yanakaribia muda wa kupandishwa'
                      : 'Will escalate to next level soon',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l;
  const _EmptyState({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(l.noComplaintsYet,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l.submitFirstComplaint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
