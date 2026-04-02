import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/push_notification_bootstrap.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_router.dart';
import 'l10n/generated/app_localizations.dart';

const _seedBlue = Color(0xFF517CB2);
const _surfaceLight = Color(0xFFF5F8FD);
const _surfaceDark = Color(0xFF0B1224);
const _cardLight = Color(0xFFFFFFFF);
const _cardDark = Color(0xFF0F1A32);

class ShiftFlowApp extends ConsumerWidget {
  const ShiftFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return PushNotificationBootstrap(
      child: MaterialApp.router(
        title: 'ShiftFlow',
        routerConfig: router,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja'), Locale('en')],
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: themeMode,
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: isDark ? const Color(0xFF4B67B3) : _seedBlue,
    onPrimary: Colors.white,
    secondary: isDark ? const Color(0xFF7AA2FF) : const Color(0xFF5E7AB8),
    onSecondary: isDark ? _surfaceDark : Colors.white,
    error: const Color(0xFFE53935),
    onError: Colors.white,
    surface: isDark ? _surfaceDark : _surfaceLight,
    onSurface: isDark ? const Color(0xFFF2F6FF) : const Color(0xFF0F172A),
    tertiary: const Color(0xFFE85D6A),
    onTertiary: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    fontFamily: 'Noto Sans JP',
  );

  return base.copyWith(
    cardTheme: CardThemeData(
      color: isDark ? _cardDark : _cardLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? const Color(0x407AA2FF) : const Color(0xFFDfe6F2),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark
          ? _surfaceDark.withValues(alpha: 0.96)
          : _surfaceLight.withValues(alpha: 0.96),
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Noto Sans JP',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF101D3A) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0x337AA2FF) : const Color(0xFFCED4DA),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0x337AA2FF) : const Color(0xFFCED4DA),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? _cardDark : const Color(0xFF1E293B),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(
          color: isDark ? const Color(0x337AA2FF) : const Color(0xFFD0DAEA),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      labelColor: scheme.primary,
      unselectedLabelColor: isDark
          ? const Color(0xFFD5DEFF)
          : const Color(0xFF475569),
      indicator: BoxDecoration(
        color: isDark ? const Color(0x2ED6E0FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              color: Color(0x29101A2A),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
        ],
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}
