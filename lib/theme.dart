import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The chalkboard palette from the HTML version.
class Chalk {
  static const green = Color(0xFF2E4636);
  static const greenDark = Color(0xFF22352A);
  static const card = Color(0xFF365443);
  static const white = Color(0xFFF7F3E8);
  static const yellow = Color(0xFFF4C95D);
  static const coral = Color(0xFFE8735C);
  static const sky = Color(0xFF6FA8DC);
  static const grass = Color(0xFF7FB069);
  static const lilac = Color(0xFFB39DDB);
  static const ink = Color(0xFF1B2A20);

  /// Colours of the hopscotch squares, in order.
  static const trail = [coral, yellow, sky, grass, lilac];

  /// Chalk white at the given opacity (0 to 1).
  static Color whiteA(double opacity) => white.withAlpha((opacity * 255).round());

  /// Headings and numbers (Baloo 2).
  static TextStyle display(double size, {Color color = white, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.baloo2(fontSize: size, fontWeight: weight, color: color);

  /// Body text and the words themselves (Nunito).
  static TextStyle body(
    double size, {
    Color color = white,
    FontWeight weight = FontWeight.w700,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color, fontStyle: style);
}
