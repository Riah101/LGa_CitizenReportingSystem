import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Tanzanian civic palette
  static const Color primaryGreen = Color(0xFF1B8A5A);
  static const Color primaryGreenDark = Color(0xFF136642);
  static const Color primaryGreenLight = Color(0xFFD4F0E3);
  static const Color accentGold = Color(0xFFFFC107);
  static const Color accentBlue = Color(0xFF1565C0);

  // Status Colors
  static const Color statusPending = Color(0xFFFF8F00);
  static const Color statusInProgress = Color(0xFF1565C0);
  static const Color statusEscalated = Color(0xFFD32F2F);
  static const Color statusResolved = Color(0xFF2E7D32);
  static const Color statusClosed = Color(0xFF757575);

  // Level Colors
  static const Color levelMtaa = Color(0xFF5C6BC0);
  static const Color levelWard = Color(0xFF0288D1);
  static const Color levelDistrict = Color(0xFFFF8F00);
  static const Color levelRegion = Color(0xFFD32F2F);
  static const Color levelNational = Color(0xFF6A1B9A);

  // Neutral
  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F2);
  static const Color onSurface = Color(0xFF1A2E25);
  static const Color textSecondary = Color(0xFF6B7C74);
  static const Color divider = Color(0xFFE0EBE6);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: accentGold,
      surface: surface,
      background: background,
    ),
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.notoSansTextTheme().copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.notoSans(
        fontSize: 16,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 14,
        color: onSurface,
      ),
      bodySmall: GoogleFonts.notoSans(
        fontSize: 12,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: divider,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      iconTheme: const IconThemeData(color: onSurface),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.notoSans(color: textSecondary, fontSize: 14),
      hintStyle: GoogleFonts.notoSans(color: textSecondary, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: divider, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 1,
      space: 1,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textSecondary,
      selectedLabelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 11),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static ThemeData darkTheme = lightTheme.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1B14),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      primary: const Color(0xFF4CAF82),
      surface: const Color(0xFF1A2E25),
      background: const Color(0xFF0D1B14),
    ),
  );

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'in_progress':
        return statusInProgress;
      case 'escalated':
        return statusEscalated;
      case 'resolved':
        return statusResolved;
      case 'closed':
        return statusClosed;
      default:
        return textSecondary;
    }
  }

  static Color levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'mtaa':
        return levelMtaa;
      case 'ward':
        return levelWard;
      case 'district':
        return levelDistrict;
      case 'region':
        return levelRegion;
      case 'national':
        return levelNational;
      default:
        return textSecondary;
    }
  }
}
