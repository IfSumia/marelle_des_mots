import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pink gingham + sticker palette.
class Candy {
  static const bg = Color(0xFFFFE1EA); // gingham base
  static const stripe = Color(0xFFF7A1BF); // gingham stripes (drawn translucent)
  static const card = Color(0xFFFFFBF4); // cream paper
  static const sheet = Color(0xFFFFF1F5); // bottom sheet
  static const text = Color(0xFF5A2B44); // plum, used for text AND outlines
  static const ink = text;
  static const berry = Color(0xFFD93F6A); // accent text
  static const yellow = Color(0xFFFFD166);
  static const coral = Color(0xFFF2677F);
  static const sky = Color(0xFF8EC5F0);
  static const grass = Color(0xFF8ED6B0);
  static const lilac = Color(0xFFC3A8F2);

  /// Colours of the hopscotch squares, in order.
  static const trail = [coral, yellow, sky, grass, lilac];

  /// Plum at the given opacity (0 to 1).
  static Color textA(double opacity) => text.withAlpha((opacity * 255).round());

  /// Headings and numbers (Baloo 2).
  static TextStyle display(double size, {Color color = text, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.baloo2(fontSize: size, fontWeight: weight, color: color);

  /// Body text and the words themselves (Nunito).
  static TextStyle body(
    double size, {
    Color color = text,
    FontWeight weight = FontWeight.w700,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color, fontStyle: style);

  /// Cut-out sticker: plum outline and a hard offset shadow.
  static BoxDecoration sticker({
    Color fill = card,
    double radius = 16,
    double border = 2.5,
    double lift = 3,
  }) =>
      BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: text, width: border),
        boxShadow: [BoxShadow(color: text, offset: Offset(0, lift))],
      );
}
