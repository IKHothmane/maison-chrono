import 'package:flutter/material.dart';

const _gold = Color(0xFFC9A96E);
const _goldLight = Color(0xFFDFC28D);
const _black = Color(0xFF0A0A0A);
const _charcoal = Color(0xFF1A1A1A);
const _charcoalLight = Color(0xFF252525);
const _offwhite = Color(0xFFF5F5F0);

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _gold,
      brightness: Brightness.dark,
      surface: _charcoal,
      primary: _gold,
      onPrimary: _black,
      secondary: _goldLight,
    ),
    scaffoldBackgroundColor: _black,
    appBarTheme: AppBarTheme(
      backgroundColor: _black.withValues(alpha: 0.92),
      foregroundColor: _offwhite,
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: _gold.withValues(alpha: 0.08),
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'Serif',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: _offwhite,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.0, color: _offwhite),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: _offwhite),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: _offwhite),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _offwhite),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _offwhite),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: _offwhite, height: 1.55),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: _offwhite),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: _offwhite),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: _goldLight),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _charcoal.withValues(alpha: 0.95),
      indicatorColor: _gold.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: _gold);
        }
        return TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: _offwhite.withValues(alpha: 0.6));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _gold, size: 24);
        }
        return IconThemeData(color: _offwhite.withValues(alpha: 0.6), size: 22);
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _charcoalLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _offwhite.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _gold, width: 1.5),
      ),
      hintStyle: TextStyle(color: _offwhite.withValues(alpha: 0.35), fontWeight: FontWeight.w300),
      labelStyle: TextStyle(color: _offwhite.withValues(alpha: 0.6)),
      prefixIconColor: _offwhite.withValues(alpha: 0.5),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: _black,
        elevation: 0,
        shadowColor: _gold.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _gold,
        side: BorderSide(color: _gold.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _gold,
      foregroundColor: _black,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    cardTheme: CardThemeData(
      color: _charcoal,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _offwhite.withValues(alpha: 0.06)),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _charcoal,
      selectedColor: _gold.withValues(alpha: 0.15),
      side: BorderSide(color: _offwhite.withValues(alpha: 0.1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(color: _offwhite.withValues(alpha: 0.85), fontSize: 13),
    ),
    dividerTheme: DividerThemeData(
      color: _offwhite.withValues(alpha: 0.06),
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      titleTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _offwhite),
      subtitleTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: _offwhite.withValues(alpha: 0.6)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      dragHandleColor: _offwhite.withValues(alpha: 0.2),
      dragHandleSize: const Size(40, 4),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _charcoalLight,
      contentTextStyle: const TextStyle(color: _offwhite, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _gold,
      linearTrackColor: Color(0xFF252525),
    ),
    iconTheme: IconThemeData(color: _offwhite.withValues(alpha: 0.85), size: 22),
    dialogTheme: DialogThemeData(
      backgroundColor: _charcoal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _offwhite),
    ),
  );
}
