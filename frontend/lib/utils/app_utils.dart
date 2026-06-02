import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Sauti ya Raia';
  static const String appVersion = '1.0.0';
  static const String supportPhone = '+255800720721';
  static const String supportEmail = 'support@sautiyaraia.go.tz';

  // Storage keys
  static const String kCurrentUser = 'current_user';
  static const String kComplaints = 'complaints';
  static const String kLocale = 'locale';
  static const String kDarkMode = 'dark_mode';

  // Escalation days
  static const int mtaaDays = 7;
  static const int wardDays = 14;
  static const int districtDays = 21;
  static const int regionDays = 30;

  // Complaint limits
  static const int titleMaxLength = 100;
  static const int descriptionMinLength = 20;
  static const int descriptionMaxLength = 1000;
  static const int maxAttachments = 5;
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String submitComplaint = '/submit';
  static const String complaintDetail = '/complaint';
  static const String track = '/track';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String officerDashboard = '/officer';
}

/// Format a DateTime to a readable string
String formatDate(DateTime date, {bool includeTime = false}) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final base = '${date.day} ${months[date.month - 1]} ${date.year}';
  if (!includeTime) return base;
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$base at $h:$m';
}

/// Time ago
String timeAgo(DateTime date, {bool swahili = false}) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 365) {
    final y = (diff.inDays / 365).floor();
    return swahili ? 'miaka $y iliyopita' : '${y}y ago';
  }
  if (diff.inDays >= 30) {
    final mo = (diff.inDays / 30).floor();
    return swahili ? 'miezi $mo iliyopita' : '${mo}mo ago';
  }
  if (diff.inDays > 0) {
    return swahili ? 'siku ${diff.inDays} iliyopita' : '${diff.inDays}d ago';
  }
  if (diff.inHours > 0) {
    return swahili ? 'masaa ${diff.inHours} iliyopita' : '${diff.inHours}h ago';
  }
  if (diff.inMinutes > 0) {
    return swahili
        ? 'dakika ${diff.inMinutes} iliyopita'
        : '${diff.inMinutes}m ago';
  }
  return swahili ? 'sasa hivi' : 'just now';
}

/// Show a snackbar
void showSnack(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade600 : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ),
  );
}
