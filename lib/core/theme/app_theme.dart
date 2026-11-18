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

    // Modèle 07 style E + palette P12 : fond clair gris, cartes blanches très
    // arrondies à ombre douce, boutons pilules, marine pour les surfaces
    // fortes ; en sombre : marine profond et cartes marine.
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    const pill = StadiumBorder();
    final background = isDark ? AppColors.marineDeep : AppColors.mist;
    final cardColor = isDark ? AppColors.marine : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        secondary: isDark ? AppColors.gold : AppColors.marine,
        onSecondary: isDark ? AppColors.marineDeep : Colors.white,
        surface: background,
        surfaceContainerLowest: cardColor,
        surfaceContainerLow: cardColor,
        surfaceContainer: isDark ? const Color(0xFF1B2A4A) : Colors.white,
        surfaceContainerHighest: isDark
            ? const Color(0xFF22335A)
            : const Color(0xFFE8EAF0),
      ),
      textTheme: textTheme,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      extensions: [isDark ? RiderColors.dark : RiderColors.light],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        shadowColor: AppColors.marine.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        shape: isDark
            ? shape.copyWith(side: const BorderSide(color: Color(0x14FFFFFF)))
            : shape,
        color: cardColor,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelLarge,
        shape: pill,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: pill,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: pill,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: pill),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: pill,
        elevation: 3,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(shape: pill),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
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
