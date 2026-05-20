import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bgPrimary;
  final Color bgSurface;
  final Color bgElevated;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentWarning;
  final Color accentDanger;
  final Color accentSuccess;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color glowColor;

  const AppThemeColors({
    required this.bgPrimary,
    required this.bgSurface,
    required this.bgElevated,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentWarning,
    required this.accentDanger,
    required this.accentSuccess,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.glowColor,
  });

  @override
  AppThemeColors copyWith({
    Color? bgPrimary,
    Color? bgSurface,
    Color? bgElevated,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? accentWarning,
    Color? accentDanger,
    Color? accentSuccess,
    Color? textPrimary,
    Color? textSecondary,
    Color? borderColor,
    Color? glowColor,
  }) {
    return AppThemeColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentWarning: accentWarning ?? this.accentWarning,
      accentDanger: accentDanger ?? this.accentDanger,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      borderColor: borderColor ?? this.borderColor,
      glowColor: glowColor ?? this.glowColor,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      accentDanger: Color.lerp(accentDanger, other.accentDanger, t)!,
      accentSuccess: Color.lerp(accentSuccess, other.accentSuccess, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
    );
  }

  // Dark Theme Definition
  static const dark = AppThemeColors(
    bgPrimary: Color(0x0FF0A0E1), // #0A0E1A (using 0xFF0A0E1A, fixed below)
    bgSurface: Color(0xFF111827),
    bgElevated: Color(0xFF1C2437),
    accentPrimary: Color(0xFF00D4FF),
    accentSecondary: Color(0xFF7C3AED),
    accentWarning: Color(0xFFF59E0B),
    accentDanger: Color(0xFFEF4444),
    accentSuccess: Color(0xFF10B981),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    borderColor: Color(0xFF1F2937),
    glowColor: Color(0x3300D4FF),
  );

  // Light Theme Definition
  static const light = AppThemeColors(
    bgPrimary: Color(0xFFF3F4F6),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFE5E7EB),
    accentPrimary: Color(0xFF0D9488),
    accentSecondary: Color(0xFF4F46E5),
    accentWarning: Color(0xFFD97706),
    accentDanger: Color(0xFFDC2626),
    accentSuccess: Color(0xFF059669),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    borderColor: Color(0xFFD1D5DB),
    glowColor: Color(0x220D9488),
  );
}

// Fixed color value for dark bg primary
final AppThemeColors darkThemeColors = AppThemeColors(
  bgPrimary: const Color(0xFF0A0E1A),
  bgSurface: AppThemeColors.dark.bgSurface,
  bgElevated: AppThemeColors.dark.bgElevated,
  accentPrimary: AppThemeColors.dark.accentPrimary,
  accentSecondary: AppThemeColors.dark.accentSecondary,
  accentWarning: AppThemeColors.dark.accentWarning,
  accentDanger: AppThemeColors.dark.accentDanger,
  accentSuccess: AppThemeColors.dark.accentSuccess,
  textPrimary: AppThemeColors.dark.textPrimary,
  textSecondary: AppThemeColors.dark.textSecondary,
  borderColor: AppThemeColors.dark.borderColor,
  glowColor: AppThemeColors.dark.glowColor,
);

class AppTheme {
  static ThemeData themeData({required bool isDark}) {
    return isDark ? getDarkTheme() : getLightTheme();
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0E1A),
      primaryColor: const Color(0xFF00D4FF),
      cardColor: const Color(0xFF111827),
      dividerColor: const Color(0xFF1F2937),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.inter(color: const Color(0xFFF9FAFB)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
      ),
      extensions: [darkThemeColors],
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      primaryColor: const Color(0xFF0D9488),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFD1D5DB),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.inter(color: const Color(0xFF111827)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF4B5563)),
      ),
      extensions: [AppThemeColors.light],
    );
  }

  // Display Typography Tokens
  static TextStyle displayXl(BuildContext context, Color color) => GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 1.5,
      );

  static TextStyle headingLg(BuildContext context, Color color) => GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 1.0,
      );

  static TextStyle headingMd(BuildContext context, Color color) => GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      );

  static TextStyle bodyMd(BuildContext context, Color color) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodySm(BuildContext context, Color color) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle caption(BuildContext context, Color color) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.5,
      );

  static TextStyle monoSm(BuildContext context, Color color) => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color,
      );

  // Helper to extract custom colors easily
  static AppThemeColors of(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>();
    return colors ?? darkThemeColors;
  }
}
