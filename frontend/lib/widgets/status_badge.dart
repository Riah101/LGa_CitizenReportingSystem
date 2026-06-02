import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/complaint.dart';
import '../utils/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = AppTheme.statusColor(status.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    ));

    String label;
    IconData icon;

    switch (status) {
      case ComplaintStatus.pending:
        label = l.statusPending;
        icon = Icons.hourglass_empty_rounded;
        break;
      case ComplaintStatus.inProgress:
        label = l.statusInProgress;
        icon = Icons.autorenew_rounded;
        break;
      case ComplaintStatus.escalated:
        label = l.statusEscalated;
        icon = Icons.arrow_upward_rounded;
        break;
      case ComplaintStatus.resolved:
        label = l.statusResolved;
        icon = Icons.check_circle_outline;
        break;
      case ComplaintStatus.closed:
        label = l.statusClosed;
        icon = Icons.lock_outline;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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
    );
  }
}
