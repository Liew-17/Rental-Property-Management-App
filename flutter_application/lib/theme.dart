import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color.fromARGB(255, 1, 103, 124);
  static const Color secondaryColor = Color(0xFFFAFAFA);
  static const Color backgroundColor = Colors.white;
  static const Color accentColor = Colors.blueAccent;
  static const Color favoritedColor = Color.fromARGB(255, 255, 0, 111);



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

  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
  foregroundColor: primaryColor, 
  side: const BorderSide(color: primaryColor, width: 1.5),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8), 
  ),
  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
  );

  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      // Success / Active
      case 'listed':
      case 'active':
      case 'completed':
      case 'approved':
      case 'paid':
        return Colors.green;

      // Ongoing / Info
      case 'rented':
        return Colors.blue;

      // Warnings / Pending
      case 'unlisted':
      case 'pending':
        return Colors.orange;

      // Errors / Stopped
      case 'rejected':
      case 'terminated':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  

  
}
