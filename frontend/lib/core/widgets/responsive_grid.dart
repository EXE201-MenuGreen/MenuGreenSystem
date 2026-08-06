import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

/// A responsive grid that adapts column count based on screen size.
class ResponsiveGrid extends StatelessWidget {
  /// List of widgets to display.
  final List<Widget> children;

  /// Spacing between items.
  final double spacing;

  /// Aspect ratio of each child (width / height).
  final double childAspectRatio;

  /// Whether the grid is scrollable.
  final bool shrinkWrap;

  /// Custom column counts.
  final int? phoneColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  /// Constructor.
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.childAspectRatio = 1.5,
    this.shrinkWrap = true,
    this.phoneColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  int _getColumnCount(BuildContext context) {
    return context.valueForDevice(
      phone: phoneColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getColumnCount(context),
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive wrap that adapts spacing based on screen size.
class ResponsiveWrap extends StatelessWidget {
  /// List of widgets to display.
  final List<Widget> children;

  /// Horizontal spacing between items.
  final double horizontalSpacing;

  /// Vertical spacing between items.
  final double verticalSpacing;

  /// Horizontal run spacing.
  final double runSpacing;

  /// Alignment of items in the main axis.
  final WrapAlignment alignment;

  /// Constructor.
  const ResponsiveWrap({
    super.key,
    required this.children,
    double? horizontalSpacing,
    double? verticalSpacing,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
  })  : horizontalSpacing = horizontalSpacing ?? 16.0,
        verticalSpacing = verticalSpacing ?? 8.0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: horizontalSpacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children.map((child) {
        return Padding(
          padding: EdgeInsets.only(bottom: verticalSpacing),
          child: child,
        );
      }).toList(),
    );
  }
}

/// A responsive sliver grid.
class ResponsiveSliverGrid extends StatelessWidget {
  /// List of widgets to display.
  final List<Widget> children;

  /// Spacing between items.
  final double spacing;

  /// Aspect ratio of each child.
  final double childAspectRatio;

  /// Custom column counts.
  final int? phoneColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  /// Constructor.
  const ResponsiveSliverGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.childAspectRatio = 1.5,
    this.phoneColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  int _getColumnCount(BuildContext context) {
    return context.valueForDevice(
      phone: phoneColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getColumnCount(context),
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    );
  }
}
