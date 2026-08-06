import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Device type enumeration.
enum DeviceType {
  phone,
  tablet,
  desktop,
}

/// Extension methods on BuildContext for responsive design.
extension ResponsiveExtensions on BuildContext {
  /// Returns the device type based on screen width.
  DeviceType get deviceType {
    final width = screenWidth;
    if (width >= Breakpoints.desktop) return DeviceType.desktop;
    if (width >= Breakpoints.phone) return DeviceType.tablet;
    return DeviceType.phone;
  }

  /// Whether the current device is a phone.
  bool get isPhone => deviceType == DeviceType.phone;

  /// Whether the current device is a tablet.
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Whether the current device is a desktop.
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Whether the device is in landscape orientation.
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Whether the device is in portrait orientation.
  bool get isPortrait =>
      MediaQuery.orientationOf(this) == Orientation.portrait;

  /// Returns the screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Returns the screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Returns the shortest side of the screen.
  double get shortestSide => MediaQuery.sizeOf(this).shortestSide;

  /// Returns the longest side of the screen.
  double get longestSide => MediaQuery.sizeOf(this).longestSide;

  /// Returns safe area padding.
  EdgeInsets get safeAreaPadding => MediaQuery.paddingOf(this);

  /// Returns view insets (e.g., keyboard).
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// Whether the keyboard is visible.
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Returns a value based on the device type.
  ///
  /// Usage:
  /// ```dart
  /// final padding = context.valueForDevice(
  ///   phone: 16.0,
  ///   tablet: 24.0,
  ///   desktop: 32.0,
  /// );
  /// ```
  T valueForDevice<T>({
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.phone:
        return phone;
    }
  }

  /// Returns a responsive value based on screen width.
  ///
  /// Usage:
  /// ```dart
  /// final columns = context.valueForWidth(
  ///   < 600: 1,
  ///   < 900: 2,
  ///   else: 3,
  /// );
  /// ```
  T valueForWidth<T>({
    required T lessThan600,
    T? lessThan900,
    required T otherwise,
  }) {
    if (screenWidth < 600) return lessThan600;
    if (screenWidth < 900 && lessThan900 != null) return lessThan900;
    return otherwise;
  }

  /// Returns responsive padding for the screen.
  EdgeInsets get responsivePadding => EdgeInsets.symmetric(
        horizontal: valueForDevice(
          phone: 16.0,
          tablet: 24.0,
          desktop: 32.0,
        ),
        vertical: valueForDevice(
          phone: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
      );

  /// Returns responsive card padding.
  EdgeInsets get responsiveCardPadding => valueForDevice(
        phone: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(16),
        desktop: const EdgeInsets.all(20),
      );

  /// Returns responsive icon size.
  double get responsiveIconSize => valueForDevice(
        phone: 24.0,
        tablet: 28.0,
        desktop: 32.0,
      );

  /// Returns responsive border radius.
  double get responsiveBorderRadius => valueForDevice(
        phone: 12.0,
        tablet: 16.0,
        desktop: 20.0,
      );

  /// Returns responsive avatar radius.
  double get responsiveAvatarRadius => valueForDevice(
        phone: 20.0,
        tablet: 28.0,
        desktop: 36.0,
      );

  /// Returns responsive grid cross-axis count.
  int get responsiveGridColumns => valueForDevice(
        phone: 1,
        tablet: 2,
        desktop: 3,
      );

  /// Returns responsive quick action grid columns.
  int get responsiveQuickActionColumns => valueForDevice(
        phone: 4,
        tablet: 6,
        desktop: 8,
      );
}
