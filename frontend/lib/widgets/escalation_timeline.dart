import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/complaint.dart';
import '../utils/app_theme.dart';

class EscalationTimeline extends StatelessWidget {
  final Complaint complaint;
  final AppLocalizations l;

  const EscalationTimeline({
    super.key,
    required this.complaint,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    const levels = GovernmentLevel.values;
    final currentIndex = levels.indexOf(complaint.currentLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.escalationJourney,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          l.isSwahili
              ? 'Malalamiko yanakuwa yanapandishwa kiotomatiki kama hayashughulikiwa kwa muda uliowekwa'
              : 'Complaints auto-escalate if unaddressed within the set timeframe at each level',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        ...levels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;
          final isCompleted = index < currentIndex;
          final isCurrent = index == currentIndex;
          final isFuture = index > currentIndex;
          final isLast = index == levels.length - 1;

          // Find escalation history for this level
          final escalationEntry = complaint.escalationHistory.where((e) => e.toLevel == level).firstOrNull;
          final daysAllowed = Complaint.escalationDays[level];

          return _TimelineNode(
            level: level,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isFuture: isFuture,
            isLast: isLast,
            escalationEntry: escalationEntry,
            daysAllowed: daysAllowed,
            complaint: complaint,
            l: l,
          );
        }),

        // Auto-escalation info
        if (complaint.status != ComplaintStatus.resolved &&
            complaint.status != ComplaintStatus.closed) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.escalationInfo,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final GovernmentLevel level;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;
  final bool isLast;
  final EscalationHistory? escalationEntry;
  final int? daysAllowed;
  final Complaint complaint;
  final AppLocalizations l;

  const _TimelineNode({
    required this.level,
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
    required this.isLast,
    required this.escalationEntry,
    required this.daysAllowed,
    required this.complaint,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.levelColor(level.name);
    final nodeColor = isCompleted
        ? color
        : isCurrent
            ? color
            : AppTheme.divider;

    String levelName;
    String levelSubtitle;
    switch (level) {
      case GovernmentLevel.mtaa:
        levelName = 'Mtaa';
        levelSubtitle = l.isSwahili ? 'Ngazi ya kwanza' : 'First level';
        break;
      case GovernmentLevel.ward:
        levelName = l.isSwahili ? 'Kata' : 'Ward';
        levelSubtitle = l.isSwahili ? 'Baada ya siku 7' : 'After 7 days';
        break;
      case GovernmentLevel.district:
        levelName = l.isSwahili ? 'Wilaya' : 'District';
        levelSubtitle = l.isSwahili ? 'Baada ya siku 14' : 'After 14 days';
        break;
      case GovernmentLevel.region:
        levelName = l.isSwahili ? 'Mkoa' : 'Region';
        levelSubtitle = l.isSwahili ? 'Baada ya siku 21' : 'After 21 days';
        break;
      case GovernmentLevel.national:
        levelName = l.isSwahili ? 'Taifa' : 'National';
        levelSubtitle = l.isSwahili ? 'Baada ya siku 30' : 'After 30 days';
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + node
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? color.withOpacity(0.12)
                        : AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: nodeColor,
                      width: isCurrent ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check_rounded,
                            color: color, size: 18)
                        : isCurrent
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : Text(
                                '${GovernmentLevel.values.indexOf(level) + 1}',
                                style: TextStyle(
                                  color: isFuture
                                      ? AppTheme.textSecondary
                                      : color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? color.withOpacity(0.4)
                          : AppTheme.divider,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  left: 8, bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        levelName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isFuture ? AppTheme.textSecondary : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l.isSwahili ? 'SASA' : 'CURRENT',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    levelSubtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: isFuture
                            ? AppTheme.textSecondary.withOpacity(0.5)
                            : AppTheme.textSecondary),
                  ),
                  if (escalationEntry != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l.isSwahili ? "Imepandishwa" : "Escalated"}: ${_formatDate(escalationEntry!.escalatedAt)}',
                      style: TextStyle(
                          fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      escalationEntry!.reason,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isCurrent &&
                      complaint.status != ComplaintStatus.resolved &&
                      complaint.status != ComplaintStatus.closed) ...[
                    const SizedBox(height: 4),
                    _DaysProgressBar(complaint: complaint, color: color, l: l),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _DaysProgressBar extends StatelessWidget {
  final Complaint complaint;
  final Color color;
  final AppLocalizations l;

  const _DaysProgressBar(
      {required this.complaint, required this.color, required this.l});

  @override
  Widget build(BuildContext context) {
    final level = complaint.currentLevel;
    final totalDays = Complaint.escalationDays[level] ?? 7;
    final daysLeft = complaint.daysUntilEscalation();
    final elapsed = totalDays - daysLeft;
    final progress = (elapsed / totalDays).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$elapsed / $totalDays ${l.isSwahili ? "siku" : "days"}',
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary),
            ),
            Text(
              '$daysLeft ${l.daysRemaining}',
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
