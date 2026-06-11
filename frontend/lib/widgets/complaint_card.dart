import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/complaint.dart';
import '../utils/app_theme.dart';
import 'status_badge.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final daysLeft = complaint.daysUntilEscalation();
    final isWarning = daysLeft <= 2 &&
        daysLeft >= 0 &&
        complaint.status != ComplaintStatus.resolved &&
        complaint.status != ComplaintStatus.closed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWarning
                ? AppTheme.statusEscalated.withOpacity(0.4)
                : AppTheme.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning strip
            if (isWarning)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: const BoxDecoration(
                  color: AppTheme.statusEscalated,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      l.isSwahili
                          ? 'Itapandishwa kwa siku $daysLeft'
                          : 'Escalates in $daysLeft day${daysLeft != 1 ? "s" : ""}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category emoji
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.levelColor(complaint.currentLevel.name)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            _categoryEmoji(complaint.category),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${complaint.mtaa}, ${complaint.ward}',
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusBadge(
                            status: complaint.status,
                            compact: true,
                          ),
                          const SizedBox(height: 4),
                          _LevelPill(level: complaint.currentLevel),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    complaint.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 10),

                  // Footer
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text('${complaint.upvotes}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 12),
                      const Icon(Icons.comment_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text('${complaint.comments.length}',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (complaint.isUrgent) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.priority_high,
                            size: 13, color: AppTheme.statusEscalated),
                        const Text(
                          'URGENT',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.statusEscalated,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _timeAgo(complaint.submittedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(ComplaintCategory cat) {
    switch (cat) {
      case ComplaintCategory.infrastructure: return '🏗️';
      case ComplaintCategory.water: return '💧';
      case ComplaintCategory.electricity: return '⚡';
      case ComplaintCategory.health: return '🏥';
      case ComplaintCategory.education: return '🎓';
      case ComplaintCategory.security: return '🛡️';
      case ComplaintCategory.environment: return '🌿';
      case ComplaintCategory.socialServices: return '👥';
      case ComplaintCategory.corruption: return '⚖️';
      case ComplaintCategory.other: return '📋';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

class _LevelPill extends StatelessWidget {
  final GovernmentLevel level;
  const _LevelPill({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.levelColor(level.name);
    String label;
    switch (level) {
      case GovernmentLevel.mtaa: label = 'Mtaa'; break;
      case GovernmentLevel.ward: label = 'Kata'; break;
      case GovernmentLevel.district: label = 'Wilaya'; break;
      case GovernmentLevel.region: label = 'Mkoa'; break;
      case GovernmentLevel.national: label = 'Taifa'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}
