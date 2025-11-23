import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color.fromARGB(255, 1, 103, 124);
  static const Color secondaryColor = Color(0xFF1E1E1E);
  static const Color backgroundColor = Colors.white;
  static const Color accentColor = Colors.blueAccent;
  static const Color favoritedColor = Color.fromARGB(255, 255, 0, 111);

  // Text styles
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
  );

  static TextStyle bodyText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: secondaryColor,
  );

  // Button style
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
  );
}
