import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'radius.dart';

ThemeData buildDarkTheme() {
  final cs = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkAccent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.darkAccentTint,
    onPrimaryContainer: AppColors.darkAccentPress,
    secondary: AppColors.darkAccentSoft,
    onSecondary: AppColors.darkAccentPress,
    secondaryContainer: AppColors.darkAccentTint,
    onSecondaryContainer: AppColors.darkAccentPress,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText1,
    surfaceContainerHighest: AppColors.darkSurfaceSunken,
    surfaceContainerLow: AppColors.darkBg,
    onSurfaceVariant: AppColors.darkText3,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorderSoft,
    shadow: const Color(0x1A000000),
    scrim: const Color(0x66000000),
    inverseSurface: AppColors.surface,
    onInverseSurface: AppColors.text1,
    inversePrimary: AppColors.accentPress,
  );

  final text = AppTypography.buildTextTheme(cs);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: text,
    scaffoldBackgroundColor: AppColors.darkBg,
    dividerColor: AppColors.darkDivider,
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(color: AppColors.darkBorderSoft),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.darkBorderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.darkBorderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.darkAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: text.bodyLarge?.copyWith(color: AppColors.darkText4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface.withValues(alpha: 0.92),
      indicatorColor: AppColors.darkAccentTint,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.darkAccentPress);
        }
        return const IconThemeData(color: AppColors.darkText3);
      }),
      elevation: 0,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: text.headlineMedium?.copyWith(color: AppColors.darkText1),
      iconTheme: const IconThemeData(color: AppColors.darkText2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : AppColors.darkText4),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.darkAccent
              : AppColors.darkSurfaceRaised),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 0,
    ),
  );
}
