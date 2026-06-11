import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/complaint.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _cleared = false;

  Future<void> _confirmClearAll(AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.isSwahili ? 'Futa Zote' : 'Clear All'),
        content: Text(l.clearAllNotifications),
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
      setState(() => _cleared = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.notificationsCleared),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final complaints = context.watch<ComplaintProvider>().complaints;

    // Generate synthetic notifications from complaint activity
    final notifications = _cleared ? <_AppNotification>[] : _buildNotifications(complaints, l);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifications),
        actions: [
          if (!_cleared)
            TextButton(
              onPressed: () => _confirmClearAll(l),
              child: Text(
                l.isSwahili ? 'Futa Zote' : 'Clear All',
                style: const TextStyle(color: AppTheme.primaryGreen),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 56, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    l.isSwahili ? 'Hakuna arifa' : 'No notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifications[i];
                return _NotificationTile(notification: n);
              },
            ),
    );
  }

  List<_AppNotification> _buildNotifications(
      List<Complaint> complaints, AppLocalizations l) {
    final List<_AppNotification> result = [];

    for (final c in complaints) {
      // Escalation notifications
      for (final e in c.escalationHistory) {
        result.add(_AppNotification(
          title: l.isSwahili
              ? 'Lalamiko Limepandishwa'
              : 'Complaint Escalated',
          body: l.isSwahili
              ? '${c.title} imepandishwa hadi ngazi ya ${_levelName(e.toLevel, l)}'
              : '${c.title} escalated to ${_levelName(e.toLevel, l)} level',
          icon: Icons.arrow_upward_rounded,
          color: AppTheme.statusEscalated,
          time: e.escalatedAt,
          trackingCode: c.trackingCode,
        ));
      }

      // Resolved notifications
      if (c.resolvedAt != null) {
        result.add(_AppNotification(
          title: l.isSwahili ? 'Imesuluhiwa!' : 'Resolved!',
          body: l.isSwahili
              ? '${c.title} imesuluhiwa'
              : '${c.title} has been resolved',
          icon: Icons.check_circle_outline,
          color: AppTheme.statusResolved,
          time: c.resolvedAt!,
          trackingCode: c.trackingCode,
        ));
      }

      // Comment notifications
      for (final comment in c.comments.where((cm) => cm.isOfficial)) {
        result.add(_AppNotification(
          title: l.isSwahili ? 'Jibu Rasmi' : 'Official Response',
          body: l.isSwahili
              ? '${comment.authorName} amejibu lalamiko lako'
              : '${comment.authorName} responded to your complaint',
          icon: Icons.comment_outlined,
          color: AppTheme.accentBlue,
          time: comment.createdAt,
          trackingCode: c.trackingCode,
        ));
      }
    }

    result.sort((a, b) => b.time.compareTo(a.time));
    return result;
  }

  String _levelName(GovernmentLevel lvl, AppLocalizations l) {
    switch (lvl) {
      case GovernmentLevel.ward: return l.isSwahili ? 'Kata' : 'Ward';
      case GovernmentLevel.district: return l.isSwahili ? 'Wilaya' : 'District';
      case GovernmentLevel.region: return l.isSwahili ? 'Mkoa' : 'Region';
      case GovernmentLevel.national: return l.isSwahili ? 'Taifa' : 'National';
      default: return 'Mtaa';
    }
  }
}

class _AppNotification {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime time;
  final String trackingCode;

  _AppNotification({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.time,
    required this.trackingCode,
  });
}

class _NotificationTile extends StatelessWidget {
  final _AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon,
                color: notification.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      _timeAgo(notification.time),
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notification.body,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.trackingCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}
