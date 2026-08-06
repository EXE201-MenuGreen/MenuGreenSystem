import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

/// Spacing constants following a consistent scale.
class Spacing {
  Spacing._();

  /// Extra small spacing.
  static const double xs = 4.0;

  /// Small spacing.
  static const double sm = 8.0;

  /// Medium spacing (default).
  static const double md = 16.0;

  /// Large spacing.
  static const double lg = 24.0;

  /// Extra large spacing.
  static const double xl = 32.0;

  /// Double extra large spacing.
  static const double xxl = 48.0;

  /// Triple extra large spacing.
  static const double xxxl = 64.0;

  // Screen padding presets.

  /// Standard screen horizontal padding.
  static const double screenPaddingHorizontal = 16.0;

  /// Standard screen vertical padding.
  static const double screenPaddingVertical = 16.0;

  /// Card padding.
  static const double cardPadding = 12.0;

  /// Large card padding.
  static const double cardPaddingLarge = 16.0;

  /// Screen horizontal padding.
  static EdgeInsets screenHorizontalPadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: context.screenWidth * 0.04.clamp(16.0, 32.0));

  /// Screen padding for current device type.
  static EdgeInsets screenPadding(BuildContext context) =>
      context.responsivePadding;

  /// Card padding for current device type.
  static EdgeInsets cardPaddingForDevice(BuildContext context) =>
      context.responsiveCardPadding;
}

/// Border radius constants.
class Radii {
  Radii._();

  /// Small radius.
  static const double sm = 8.0;

  /// Medium radius.
  static const double md = 12.0;

  /// Large radius.
  static const double lg = 16.0;

  /// Extra large radius.
  static const double xl = 20.0;

  /// Extra extra large radius.
  static const double xxl = 24.0;

  /// Full radius (circular).
  static const double full = 9999.0;

  /// Border radius presets.
  static BorderRadius smallRadius(BuildContext context) =>
      BorderRadius.circular(context.valueForDevice(phone: 8, tablet: 12, desktop: 12));

  static BorderRadius mediumRadius(BuildContext context) =>
      BorderRadius.circular(context.valueForDevice(phone: 12, tablet: 16, desktop: 16));

  static BorderRadius largeRadius(BuildContext context) =>
      BorderRadius.circular(context.valueForDevice(phone: 16, tablet: 20, desktop: 20));

  static BorderRadius cardRadius(BuildContext context) =>
      BorderRadius.circular(context.responsiveBorderRadius);
}

/// Icon size constants.
class IconSizes {
  IconSizes._();

  /// Extra small icon.
  static const double xs = 16.0;

  /// Small icon.
  static const double sm = 20.0;

  /// Medium icon (default).
  static const double md = 24.0;

  /// Large icon.
  static const double lg = 32.0;

  /// Extra large icon.
  static const double xl = 48.0;

  /// Extra extra large icon.
  static const double xxl = 64.0;
}

/// Elevation constants.
class Elevations {
  Elevations._();

  /// No elevation (flat).
  static const double none = 0.0;

  /// Subtle elevation (cards).
  static const double subtle = 1.0;

  /// Low elevation (floating elements).
  static const double low = 2.0;

  /// Medium elevation (dialogs).
  static const double medium = 4.0;

  /// High elevation (navigation).
  static const double high = 8.0;
}
