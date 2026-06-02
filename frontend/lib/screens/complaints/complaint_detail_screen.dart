import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/complaint.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/escalation_timeline.dart';
import '../../widgets/status_badge.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _commentCtrl = TextEditingController();
  late Complaint _complaint;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
  }

  Future<void> _addComment() async {
    if (_commentCtrl.text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    final comment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: user.id,
      authorName: user.name,
      authorRole: user.roleLabel,
      content: _commentCtrl.text,
      createdAt: DateTime.now(),
    );
    await context.read<ComplaintProvider>().addComment(_complaint.id, comment);
    _commentCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final complaint = context
            .watch<ComplaintProvider>()
            .complaints
            .where((c) => c.id == _complaint.id)
            .firstOrNull ??
        _complaint;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.complaintDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Level Header
            Row(
              children: [
                StatusBadge(status: complaint.status),
                const SizedBox(width: 8),
                _LevelBadge(level: complaint.currentLevel, l: l),
                const Spacer(),
                if (complaint.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusEscalated.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.statusEscalated.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.priority_high,
                            size: 12, color: AppTheme.statusEscalated),
                        const SizedBox(width: 4),
                        const Text('URGENT',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.statusEscalated)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(complaint.title,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),

            // Meta
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(complaint.submittedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${complaint.mtaa}, ${complaint.ward}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(complaint.categoryLabel,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.person_outline,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  complaint.isAnonymous ? 'Anonymous' : complaint.citizenName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tracking Code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    l.trackingCode + ': ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    complaint.trackingCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.primaryGreen,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(l.complaintDescription,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(complaint.description,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 24),

            // Escalation Timeline
            EscalationTimeline(complaint: complaint, l: l),
            const SizedBox(height: 24),

            // Days until next escalation
            if (complaint.status != ComplaintStatus.resolved &&
                complaint.status != ComplaintStatus.closed)
              _EscalationCountdown(complaint: complaint, l: l),
            const SizedBox(height: 24),

            // Upvotes
            _UpvoteSection(complaint: complaint, l: l),
            const SizedBox(height: 24),

            // Comments
            _CommentsSection(
              complaint: complaint,
              commentCtrl: _commentCtrl,
              onAddComment: _addComment,
              l: l,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _LevelBadge extends StatelessWidget {
  final GovernmentLevel level;
  final AppLocalizations l;

  const _LevelBadge({required this.level, required this.l});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.levelColor(level.name);
    String label;
    switch (level) {
      case GovernmentLevel.mtaa:
        label = l.isSwahili ? 'Mtaa' : 'Mtaa';
        break;
      case GovernmentLevel.ward:
        label = l.isSwahili ? 'Kata' : 'Ward';
        break;
      case GovernmentLevel.district:
        label = l.isSwahili ? 'Wilaya' : 'District';
        break;
      case GovernmentLevel.region:
        label = l.isSwahili ? 'Mkoa' : 'Region';
        break;
      case GovernmentLevel.national:
        label = l.isSwahili ? 'Taifa' : 'National';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EscalationCountdown extends StatelessWidget {
  final Complaint complaint;
  final AppLocalizations l;

  const _EscalationCountdown(
      {required this.complaint, required this.l});

  @override
  Widget build(BuildContext context) {
    final days = complaint.daysUntilEscalation();
    final isOverdue = days == 0;
    final color =
        isOverdue ? AppTheme.statusEscalated : AppTheme.statusPending;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
              isOverdue
                  ? Icons.warning_amber_rounded
                  : Icons.timer_outlined,
              color: color,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.nextEscalation,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  isOverdue
                      ? (l.isSwahili
                          ? 'Tayari imeisha muda - itapandishwa hivi karibuni'
                          : 'Overdue – will escalate soon')
                      : '$days ${l.daysRemaining}',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
          if (complaint.nextLevel() != null)
            Text(
              '→ ${_levelName(complaint.nextLevel()!, l)}',
              style: TextStyle(
                  color: AppTheme.levelColor(complaint.nextLevel()!.name),
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
        ],
      ),
    );
  }

  String _levelName(GovernmentLevel lvl, AppLocalizations l) {
    switch (lvl) {
      case GovernmentLevel.ward: return l.isSwahili ? 'Kata' : 'Ward';
      case GovernmentLevel.district: return l.isSwahili ? 'Wilaya' : 'District';
      case GovernmentLevel.region: return l.isSwahili ? 'Mkoa' : 'Region';
      case GovernmentLevel.national: return l.isSwahili ? 'Taifa' : 'National';
      default: return '';
    }
  }
}

class _UpvoteSection extends StatelessWidget {
  final Complaint complaint;
  final AppLocalizations l;

  const _UpvoteSection({required this.complaint, required this.l});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () =>
              context.read<ComplaintProvider>().upvoteComplaint(complaint.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.thumb_up_outlined,
                    size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  '${complaint.upvotes} ${l.upvotes}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final Complaint complaint;
  final TextEditingController commentCtrl;
  final VoidCallback onAddComment;
  final AppLocalizations l;

  const _CommentsSection({
    required this.complaint,
    required this.commentCtrl,
    required this.onAddComment,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l.comments} (${complaint.comments.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // Add comment field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentCtrl,
                decoration: InputDecoration(
                  hintText: l.writeComment,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onAddComment,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (complaint.comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(l.noComments,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary)),
            ),
          )
        else
          ...complaint.comments.map((c) => _CommentTile(comment: c, l: l)),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final AppLocalizations l;

  const _CommentTile({required this.comment, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: comment.isOfficial
            ? AppTheme.primaryGreenLight
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: comment.isOfficial
            ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.authorName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (comment.isOfficial) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l.officialResponse,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${comment.createdAt.day}/${comment.createdAt.month}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.authorRole,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.primaryGreen)),
          const SizedBox(height: 6),
          Text(comment.content,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
