/// EscalationService
/// 
/// Handles auto-escalation rules and scheduling.
/// In a production app this would integrate with:
///  - Firebase Cloud Functions for server-side cron jobs
///  - Flutter local_notifications for background checks
///  - Push notifications via FCM when escalations occur
///
/// Currently runs on app startup and refresh.
///
/// Escalation Schedule:
///   Mtaa    → Ward     : 7 days of inaction
///   Ward    → District : 14 days of inaction
///   District→ Region   : 21 days of inaction
///   Region  → National : 30 days of inaction

class EscalationService {
  /// Returns a human-readable escalation schedule description
  static Map<String, String> get scheduleDescription => {
        'Mtaa → Ward': '7 days',
        'Ward → District': '14 days',
        'District → Region': '21 days',
        'Region → National': '30 days',
      };

  /// Total escalation days across all levels
  static const int maxEscalationDays = 7 + 14 + 21 + 30; // 72 days total

  /// Priority boost for urgent complaints (days reduction)
  static const int urgentDaysReduction = 2;
}
