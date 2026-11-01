import 'package:flutter/material.dart';

/// Premium shared visual system for Berberim.
/// This file contains presentation only; authentication, Firestore and callable
/// function flows remain in main.dart unchanged.
abstract final class BerberimTheme {
  static const gold = Color(0xFFD6A64B);
  static const goldLight = Color(0xFFF3D28A);
  static const background = Color(0xFF090A0C);
  static const surface = Color(0xFF14161A);
  static const surfaceRaised = Color(0xFF1C1F24);
  static const muted = Color(0xFF9298A3);
  static const border = Color(0xFF2B2F36);

  static ThemeData get dark {
    final scheme = const ColorScheme.dark(
      primary: gold,
      onPrimary: Color(0xFF17130B),
      secondary: goldLight,
      onSecondary: Color(0xFF17130B),
      surface: surface,
      onSurface: Color(0xFFF5F2EB),
      error: Color(0xFFFF6B70),
      onError: Color(0xFF25090B),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(fontSize: 32, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -1.1, color: Color(0xFFF7F4ED)),
        headlineMedium: const TextStyle(fontSize: 26, height: 1.16, fontWeight: FontWeight.w800, letterSpacing: -.7, color: Color(0xFFF7F4ED)),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.35, color: Color(0xFFF7F4ED)),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF7F4ED)),
        bodyLarge: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFFE8E5DE)),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFFB9BEC7)),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: .15),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Color(0xFFF7F4ED),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.35, color: Color(0xFFF7F4ED)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: border, width: .8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: muted),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gold, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6B70))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF6B70), width: 1.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF17130B),
          disabledBackgroundColor: gold.withValues(alpha: .35),
          disabledForegroundColor: const Color(0xFF17130B).withValues(alpha: .55),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldLight,
          side: const BorderSide(color: Color(0xFF66512D)),
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: goldLight, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      iconTheme: const IconThemeData(color: goldLight, size: 22),
      listTileTheme: const ListTileThemeData(
        iconColor: goldLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 5),
        titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFF7F4ED)),
        subtitleTextStyle: TextStyle(fontSize: 13, height: 1.4, color: muted),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceRaised,
        selectedColor: gold.withValues(alpha: .18),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        labelStyle: const TextStyle(color: Color(0xFFE8E5DE), fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: goldLight, fontWeight: FontWeight.w700),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: border)),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFF7F4ED)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceRaised,
        contentTextStyle: const TextStyle(color: Color(0xFFF7F4ED), fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold, linearTrackColor: surfaceRaised),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? gold : muted),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? gold.withValues(alpha: .28) : surfaceRaised),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        headerBackgroundColor: surfaceRaised,
        headerForegroundColor: goldLight,
        todayBorder: const BorderSide(color: gold),
      ),
    );
  }
}
