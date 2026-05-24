import 'package:flutter/material.dart';

/// Animation tokens from design spec
class AppAnimations {
  AppAnimations._();

  // Durations
  static const Duration fast    = Duration(milliseconds: 120);
  static const Duration normal  = Duration(milliseconds: 220);
  static const Duration slow    = Duration(milliseconds: 320);
  static const Duration sheet   = Duration(milliseconds: 340);
  static const Duration modal   = Duration(milliseconds: 280);

  // Curves
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve spring = Cubic(0.22, 1.0, 0.36, 1.0); // cubic-bezier(0.22, 1, 0.36, 1)
  static const Curve backdropIn = Curves.easeIn;

  // Scale for tap active state
  static const double pressScale = 0.97;
}
