import 'package:flutter/material.dart';

import 'ui/chess_screen.dart';
import 'ui/palette.dart';

void main() => runApp(const ChessApp());

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Шахматы 2.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.background,
        colorScheme: const ColorScheme.dark(
          primary: Palette.gold,
          onPrimary: Palette.background,
          secondary: Palette.sage,
          surface: Palette.panel,
          onSurface: Palette.ivory,
          outline: Palette.border,
        ),
        fontFamily: 'sans-serif',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(height: 1.5),
          bodySmall: TextStyle(height: 1.5),
        ),
        dividerColor: Palette.border,
        tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: Palette.ivory,
            side: const BorderSide(color: Palette.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const ChessScreen(),
    );
  }
}
