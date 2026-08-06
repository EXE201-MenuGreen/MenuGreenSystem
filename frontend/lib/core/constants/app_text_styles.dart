import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../utils/responsive_helper.dart';

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle progressText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
    letterSpacing: 1.5,
  );
}

/// Extension for responsive text styles on BuildContext.
extension ResponsiveTextStyles on BuildContext {
  /// Responsive heading 1 style.
  TextStyle get responsiveHeading1 => TextStyle(
        fontSize: valueForDevice(
          phone: 28.0,
          tablet: 34.0,
          desktop: 40.0,
        ),
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        letterSpacing: -0.5,
      );

  /// Responsive heading 2 style.
  TextStyle get responsiveHeading2 => TextStyle(
        fontSize: valueForDevice(
          phone: 24.0,
          tablet: 28.0,
          desktop: 34.0,
        ),
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      );

  /// Responsive heading 3 style.
  TextStyle get responsiveHeading3 => TextStyle(
        fontSize: valueForDevice(
          phone: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        ),
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  /// Responsive subtitle style.
  TextStyle get responsiveSubtitle => TextStyle(
        fontSize: valueForDevice(
          phone: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        ),
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// Responsive body style.
  TextStyle get responsiveBody => TextStyle(
        fontSize: valueForDevice(
          phone: 14.0,
          tablet: 16.0,
          desktop: 16.0,
        ),
        color: AppColors.textSecondary,
      );

  /// Responsive caption style.
  TextStyle get responsiveCaption => TextStyle(
        fontSize: valueForDevice(
          phone: 12.0,
          tablet: 14.0,
          desktop: 14.0,
        ),
        color: AppColors.textLight,
      );

  /// Responsive button text style.
  TextStyle get responsiveButton => TextStyle(
        fontSize: valueForDevice(
          phone: 14.0,
          tablet: 16.0,
          desktop: 16.0,
        ),
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  /// Responsive font size multiplier.
  double get responsiveFontScale => valueForDevice(
        phone: 1.0,
        tablet: 1.15,
        desktop: 1.25,
      );
}
