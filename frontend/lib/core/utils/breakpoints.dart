/// Breakpoint constants for responsive design.
///
/// Based on Flutter's recommended breakpoints:
/// - Phone: < 600dp
/// - Tablet: 600dp - 899dp
/// - Desktop: >= 900dp
class Breakpoints {
  Breakpoints._();

  /// Maximum width for phone devices.
  static const double phone = 600;

  /// Maximum width for tablet devices.
  static const double tablet = 900;

  /// Maximum width for small desktop / large tablet landscape.
  static const double desktop = 1200;

  /// Maximum width for large desktop monitors.
  static const double largeDesktop = 1536;

  /// Short side breakpoints (for orientation-aware layouts).
  static const double compact = 480;

  /// Grid column breakpoints.
  static const int phoneColumns = 1;
  static const int tabletColumns = 2;
  static const int desktopColumns = 3;
}
