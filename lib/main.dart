import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/portfolio_data.dart';
import 'universe/universe_page.dart';

void main() {
  runApp(const BigBangPortfolioApp());
}

class BigBangPortfolioApp extends StatelessWidget {
  const BigBangPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      useMaterial3: true,
    );
    return MaterialApp(
      title: kPageTitle,
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        // Orbitron for cosmic display type, Space Grotesk for body —
        // applied per-widget where needed; this sets the default.
        textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
      ),
      home: const UniversePage(),
    );
  }
}
