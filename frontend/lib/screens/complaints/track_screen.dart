import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/complaint.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/escalation_timeline.dart';
import 'complaint_detail_screen.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _codeCtrl = TextEditingController();
  Complaint? _found;
  bool _searched = false;

  void _track() {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    final result =
        context.read<ComplaintProvider>().findByTrackingCode(code);
    setState(() {
      _found = result;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.trackComplaint)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.08),
                    AppTheme.primaryGreenLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.track_changes_rounded,
                      size: 56, color: AppTheme.primaryGreen),
                  const SizedBox(height: 12),
                  Text(
                    l.trackComplaint,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.isSwahili
                        ? 'Weka nambari ya ufuatiliaji kujua hali ya lalamiko lako'
                        : 'Enter your tracking code to check the status of your complaint',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(l.trackingCode,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'SR4K9X2M',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.5),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                      ),
                      prefixIcon: const Icon(Icons.qr_code),
                    ),
                    onSubmitted: (_) => _track(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _track,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                  child: Text(l.trackNow),
                ),
              ],
            ),

            // Demo hint
            const SizedBox(height: 8),
            Text(
              l.isSwahili
                  ? 'Demo: Jaribu SR4K9X2M, SR7B3N1P, SR2D8F5R, SR9W1L6T'
                  : 'Demo codes: SR4K9X2M · SR7B3N1P · SR2D8F5R · SR9W1L6T',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 28),

            if (_searched) ...[
              if (_found == null)
                _NotFound(l: l)
              else
                _TrackResult(complaint: _found!, l: l),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  final AppLocalizations l;
  const _NotFound({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(
            l.complaintNotFound,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.red.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            l.isSwahili
                ? 'Hakuna lalamiko lenye nambari hiyo. Tafadhali angalia tena.'
                : 'No complaint found with that tracking code. Please check and try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }
}

class _TrackResult extends StatelessWidget {
  final Complaint complaint;
  final AppLocalizations l;

  const _TrackResult({required this.complaint, required this.l});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle,
                color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              l.isSwahili ? 'Lalamiko Limepatikana' : 'Complaint Found',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ComplaintCard(
          complaint: complaint,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintDetailScreen(complaint: complaint),
            ),
          ),
        ),
        const SizedBox(height: 20),
        EscalationTimeline(complaint: complaint, l: l),
      ],
    );
  }
}
