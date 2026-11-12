import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Thèmes Material 3 clair et sombre de Rider Group.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );
    // Contrastes renforcés : texte secondaire plus franc, contours nets.
    final scheme = base.copyWith(
      primary: isDark ? const Color(0xFFFF8A4C) : const Color(0xFFC2410C),
      onPrimary: isDark ? const Color(0xFF2A1205) : Colors.white,
      onSurfaceVariant: isDark
          ? const Color(0xFFD9CCC6)
          : const Color(0xFF4A3F3A),
      outlineVariant: isDark
          ? const Color(0xFF4D423E)
          : const Color(0xFFD8CCC6),
    );
    final textTheme = _textTheme(
      (isDark
          ? Typography.material2021().white
          : Typography.material2021().black),
      scheme,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.asphalt : scheme.surface,
      extensions: [isDark ? RiderColors.dark : RiderColors.light],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isDark ? AppColors.asphalt : scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
        color: isDark ? const Color(0xFF26201E) : Colors.white,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelLarge,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: shape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  /// Titres en Barlow Condensed (condensée, dynamique, lisible en mouvement),
  /// texte courant inchangé pour la lecture.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    const display = 'BarlowCondensed';
    TextStyle? head(
      TextStyle? s, {
      FontWeight w = FontWeight.w700,
      double ls = 0.2,
    }) => s?.copyWith(
      fontFamily: display,
      fontWeight: w,
      letterSpacing: ls,
      height: 1.1,
    );
    return base.copyWith(
      displayLarge: head(base.displayLarge, w: FontWeight.w800),
      displayMedium: head(base.displayMedium, w: FontWeight.w800),
      displaySmall: head(base.displaySmall, w: FontWeight.w800),
      headlineLarge: head(base.headlineLarge, w: FontWeight.w800),
      headlineMedium: head(base.headlineMedium, w: FontWeight.w800),
      headlineSmall: head(base.headlineSmall, w: FontWeight.w800, ls: 0.3),
      titleLarge: head(base.titleLarge, ls: 0.3)?.copyWith(fontSize: 24),
      titleMedium: head(base.titleMedium, ls: 0.2)?.copyWith(fontSize: 20),
      titleSmall: head(
        base.titleSmall,
        w: FontWeight.w600,
        ls: 0.4,
      )?.copyWith(fontSize: 17),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: base.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
