import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';
import '../utils/responsive_helper.dart';

/// A widget that displays different layouts based on screen width.
///
/// This is the primary widget for adaptive layouts.
class AdaptiveLayout extends StatelessWidget {
  /// Widget to display on phones.
  final Widget phone;

  /// Widget to display on tablets.
  final Widget? tablet;

  /// Widget to display on desktop.
  final Widget? desktop;

  /// Breakpoint configurations (optional, uses defaults if not provided).
  final double? tabletBreakpoint;

  /// Constructor.
  const AdaptiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
    this.tabletBreakpoint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = tabletBreakpoint ?? Breakpoints.phone;
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? phone;
        }
        if (constraints.maxWidth >= breakpoint) {
          return tablet ?? phone;
        }
        return phone;
      },
    );
  }
}

/// A widget that shows a different widget based on orientation.
class OrientationLayout extends StatelessWidget {
  /// Widget for portrait orientation.
  final Widget portrait;

  /// Widget for landscape orientation.
  final Widget? landscape;

  /// Constructor.
  const OrientationLayout({
    super.key,
    required this.portrait,
    this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return isLandscape ? (landscape ?? portrait) : portrait;
  }
}

/// A widget that shows a different widget based on screen size category.
class ScreenSizeLayout<T extends Widget> extends StatelessWidget {
  /// Map of device types to widgets.
  final Map<DeviceType, T> children;

  /// Default widget when type not found.
  final T? fallback;

  /// Constructor.
  const ScreenSizeLayout({
    super.key,
    required this.children,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;
    return children[deviceType] ?? fallback ?? const SizedBox.shrink();
  }
}
