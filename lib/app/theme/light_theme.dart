import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'radius.dart';

ThemeData buildLightTheme() {
  final cs = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accentTint,
    onPrimaryContainer: AppColors.accentPress,
    secondary: AppColors.accentSoft,
    onSecondary: AppColors.accentPress,
    secondaryContainer: AppColors.accentTint,
    onSecondaryContainer: AppColors.accentPress,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.text1,
    surfaceContainerHighest: AppColors.surfaceSunken,
    surfaceContainerLow: AppColors.bg,
    outline: AppColors.border,
    outlineVariant: AppColors.borderSoft,
    shadow: const Color(0x0A14120C),
    scrim: const Color(0x6614120C),
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkText1,
    inversePrimary: AppColors.accent,
  );

  final text = AppTypography.buildTextTheme(cs);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: text,
    scaffoldBackgroundColor: AppColors.bg,
    dividerColor: AppColors.divider,
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    // Cards
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      margin: EdgeInsets.zero,
    ),
    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: text.bodyLarge?.copyWith(color: AppColors.text4),
    ),
    // Bottom navigation
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface.withValues(alpha: 0.92),
      indicatorColor: AppColors.accentTint,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.accentPress);
        }
        return const IconThemeData(color: AppColors.text3);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return text.labelSmall?.copyWith(color: AppColors.accentPress, letterSpacing: 0.02 * 10);
        }
        return text.labelSmall?.copyWith(color: AppColors.text3, letterSpacing: 0.02 * 10);
      }),
      elevation: 0,
    ),
    // Navigation rail (desktop)
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.bg,
      indicatorColor: AppColors.accentTint,
      selectedIconTheme: const IconThemeData(color: AppColors.accentPress),
      unselectedIconTheme: const IconThemeData(color: AppColors.text3),
      selectedLabelTextStyle: text.bodyMedium?.copyWith(
        color: AppColors.accentPress,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: text.bodyMedium?.copyWith(color: AppColors.text2),
      elevation: 0,
    ),
    // App bar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: text.headlineMedium?.copyWith(color: AppColors.text1),
      iconTheme: const IconThemeData(color: AppColors.text2),
    ),
    // Icon button
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.text2,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    ),
    // Elevated / filled buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text1,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.text2,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceSunken,
      selectedColor: AppColors.accent,
      labelStyle: text.bodyMedium?.copyWith(color: AppColors.text2),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    // Bottom sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 0,
    ),
    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      elevation: 0,
    ),
    // Switches
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : AppColors.text4),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.accent : AppColors.surfaceRaised),
    ),
    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.surfaceSunken,
    ),
    // Snack bar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.darkText1),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
