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
    if (other is! AppThemeColors) return this;
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

  // ── DARK ─────────────────────────────────────────────────────────────────
  static const dark = AppThemeColors(
    bgPrimary:       Color(0xFF0F172A), // deep navy/black
    bgSurface:       Color(0xFF1E293B), // translucent space blue
    bgElevated:      Color(0xFF334155), // solid space blue
    accentPrimary:   Color(0xFF10B981), // AI Purple
    accentSecondary: Color(0xFF00E5FF), // Neon Cyan
    accentWarning:   Color(0xFFFFB300), // Amber Gold
    accentDanger:    Color(0xFFFF4560), // Sell Red
    accentSuccess:   Color(0xFF00D4AA), // Buy Emerald
    textPrimary:     Color(0xFFF8FAFC), // Off-white
    textSecondary:   Color(0xFF94A3B8), // slate-400
    borderColor:     Color(0xFF334155), // Translucent purple border
    glowColor:       Color(0x00000000), // Purple neon glow
  );

  // ── LIGHT ────────────────────────────────────────────────────────────────
  static const light = AppThemeColors(
    bgPrimary:       Color(0xFFF8FAFC), // slate-50
    bgSurface:       Color(0xFFFFFFFF),
    bgElevated:      Color(0xFFF1F5F9), // slate-100
    accentPrimary:   Color(0xFF10B981), // purple
    accentSecondary: Color(0xFF00E5FF), // cyan
    accentWarning:   Color(0xFFD97706), // amber-600
    accentDanger:    Color(0xFFE11D48), // rose-600
    accentSuccess:   Color(0xFF059669), // emerald-600
    textPrimary:     Color(0xFF0F172A), // slate-900
    textSecondary:   Color(0xFF475569), // slate-600
    borderColor:     Color(0xFFE2E8F0), // slate-200
    glowColor:       Color(0x00000000), // purple glow
  );
}

// ── FIXED INSTANCE (avoids const limitation) ─────────────────────────────────
final AppThemeColors darkThemeColors = AppThemeColors(
  bgPrimary:       const Color(0xFF0F172A),
  bgSurface:       AppThemeColors.dark.bgSurface,
  bgElevated:      AppThemeColors.dark.bgElevated,
  accentPrimary:   AppThemeColors.dark.accentPrimary,
  accentSecondary: AppThemeColors.dark.accentSecondary,
  accentWarning:   AppThemeColors.dark.accentWarning,
  accentDanger:    AppThemeColors.dark.accentDanger,
  accentSuccess:   AppThemeColors.dark.accentSuccess,
  textPrimary:     AppThemeColors.dark.textPrimary,
  textSecondary:   AppThemeColors.dark.textSecondary,
  borderColor:     AppThemeColors.dark.borderColor,
  glowColor:       AppThemeColors.dark.glowColor,
);

class AppTheme {
  static ThemeData themeData({required bool isDark}) =>
      isDark ? getDarkTheme() : getLightTheme();

  // ── DARK THEME ────────────────────────────────────────────────────────────
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF10B981),
      cardColor: const Color(0xFF1E293B),
      dividerColor: const Color(0xFF334155),
      colorScheme: const ColorScheme.dark(
        primary:   Color(0xFF10B981), // purple
        secondary: Color(0xFF00E5FF), // cyan
        surface:   Color(0xFF1E293B), // glass surface
        error:     Color(0xFFFF4560), // sell red
        onPrimary:   Color(0xFF0F172A),
        onSecondary: Color(0xFF0F172A),
        onSurface:   Color(0xFFF8FAFC),
        onError:     Color(0xFFF8FAFC),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF8FAFC),
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF4560)),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF10B981),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: const Color(0xFF10B981).withOpacity(0.15),
        side: const BorderSide(color: Color(0xFF334155)),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF475569),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF10B981),
        unselectedLabelColor: const Color(0xFF475569),
        indicatorColor: const Color(0xFF10B981),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400),
        dividerColor: const Color(0xFF334155),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFF10B981)
                : const Color(0xFF475569)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFF1E293B)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF10B981),
        linearTrackColor: Color(0xFF1E293B),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF94A3B8), size: 20),
      textTheme: TextTheme(
        bodyLarge:  GoogleFonts.plusJakartaSans(color: const Color(0xFFF8FAFC), fontSize: 16),
        bodyMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14),
        bodySmall:  GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
      ),
      extensions: [darkThemeColors],
    );
  }

  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: const Color(0xFF10B981),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE2E8F0),
      colorScheme: const ColorScheme.light(
        primary:   Color(0xFF10B981),
        secondary: Color(0xFF00E5FF),
        surface:   Color(0xFFFFFFFF),
        error:     Color(0xFFE11D48),
        onPrimary:   Color(0xFFFFFFFF),
        onSecondary: Color(0xFF0F172A),
        onSurface:   Color(0xFF0F172A),
        onError:     Color(0xFFFFFFFF),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF475569)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE11D48)),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF10B981),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFF10B981).withOpacity(0.12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 13),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF10B981),
        unselectedLabelColor: const Color(0xFF94A3B8),
        indicatorColor: const Color(0xFF10B981),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400),
        dividerColor: const Color(0xFFE2E8F0),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFF10B981)
                : const Color(0xFF94A3B8)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFE2E8F0)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF10B981),
        linearTrackColor: Color(0xFFE2E8F0),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF475569), size: 20),
      textTheme: TextTheme(
        bodyLarge:  GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontSize: 16),
        bodyMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 14),
        bodySmall:  GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
      ),
      extensions: [AppThemeColors.light],
    );
  }

  // ── TYPOGRAPHY ────────────────────────────────────────────────────────────
  // Outfit for headings — clean, geometric, high-tech fintech look
  // Plus Jakarta Sans for body — warm, highly readable sans-serif
  // JetBrains Mono for logs/data — sharp monospace

  static TextStyle displayXl(BuildContext context, Color color) =>
      GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: color, letterSpacing: -0.5,
      );

  static TextStyle headingLg(BuildContext context, Color color) =>
      GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: color, letterSpacing: -0.3,
      );

  static TextStyle headingMd(BuildContext context, Color color) =>
      GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: color, letterSpacing: -0.1,
      );

  static TextStyle bodyMd(BuildContext context, Color color) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 15, fontWeight: FontWeight.w400, color: color,
      );

  static TextStyle bodySm(BuildContext context, Color color) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13, fontWeight: FontWeight.w400, color: color,
      );

  static TextStyle caption(BuildContext context, Color color) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: color, letterSpacing: 0.3,
      );

  static TextStyle monoSm(BuildContext context, Color color) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 12, fontWeight: FontWeight.w400, color: color,
      );

  // ── HELPER ────────────────────────────────────────────────────────────────
  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>() ?? darkThemeColors;
}
