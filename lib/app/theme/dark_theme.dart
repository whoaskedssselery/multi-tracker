import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'radius.dart';

ThemeData buildDarkTheme() {
  final cs = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkAccent,
    onPrimary: AppColors.darkBg,
    primaryContainer: AppColors.darkAccentTint,
    onPrimaryContainer: AppColors.darkAccentPress,
    secondary: AppColors.darkAccentSoft,
    onSecondary: AppColors.darkAccentPress,
    secondaryContainer: AppColors.darkAccentTint,
    onSecondaryContainer: AppColors.darkAccentPress,
    error: AppColors.darkDanger,
    onError: Colors.white,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText1,
    surfaceContainerHighest: AppColors.darkSurfaceSunken,
    surfaceContainerHigh: AppColors.darkSurfaceRaised,
    surfaceContainerLow: AppColors.darkBg,
    onSurfaceVariant: AppColors.darkText3,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorderSoft,
    shadow: const Color(0x00000000),
    scrim: const Color(0x80000000),
    inverseSurface: AppColors.surface,
    onInverseSurface: AppColors.text1,
    inversePrimary: AppColors.accentPress,
  );

  final text = AppTypography.buildTextTheme(cs);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: text,
    fontFamily: AppTypography.fontSans,
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
    // Bottom navigation
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface.withValues(alpha: 0.92),
      indicatorColor: AppColors.darkAccentTint,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.darkAccentPress);
        }
        return const IconThemeData(color: AppColors.darkText3);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return text.labelSmall
              ?.copyWith(color: AppColors.darkAccentPress, letterSpacing: 0.02 * 10);
        }
        return text.labelSmall
            ?.copyWith(color: AppColors.darkText3, letterSpacing: 0.02 * 10);
      }),
      elevation: 0,
    ),
    // Navigation rail (desktop)
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.darkBg,
      indicatorColor: AppColors.darkAccentTint,
      selectedIconTheme: const IconThemeData(color: AppColors.darkAccentPress),
      unselectedIconTheme: const IconThemeData(color: AppColors.darkText3),
      selectedLabelTextStyle: text.bodyMedium?.copyWith(
        color: AppColors.darkAccentPress,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: text.bodyMedium?.copyWith(color: AppColors.darkText2),
      elevation: 0,
    ),
    // App bar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: text.headlineMedium?.copyWith(color: AppColors.darkText1),
      iconTheme: const IconThemeData(color: AppColors.darkText2),
    ),
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: const ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: AppColors.darkBg,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ).copyWith(mouseCursor: WidgetStateMouseCursor.clickable),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText1,
        side: const BorderSide(color: AppColors.darkBorder),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ).copyWith(mouseCursor: WidgetStateMouseCursor.clickable),
    ),
    textButtonTheme: TextButtonThemeData(
      // Same height + padding as filled/outlined so dialog "Отмена" has the
      // same hover/tap area as the primary action next to it.
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkText2,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ).copyWith(mouseCursor: WidgetStateMouseCursor.clickable),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.darkText2,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ).copyWith(mouseCursor: WidgetStateMouseCursor.clickable),
    ),
    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceRaised,
      selectedColor: AppColors.darkAccent,
      labelStyle: text.bodyMedium?.copyWith(color: AppColors.darkText2),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    // Switches
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : AppColors.darkText4),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.darkAccent
              : AppColors.darkSurfaceRaised),
    ),
    // Bottom sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 0,
    ),
    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      elevation: 0,
    ),
    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.darkAccent,
      linearTrackColor: AppColors.darkSurfaceRaised,
    ),
    // Snack bar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceOverlay,
      contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.darkText1),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
