import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/responsive_helper.dart';

/// A scaffold with adaptive navigation (BottomNavigationBar + NavigationRail).
class AdaptiveScaffold extends StatelessWidget {
  /// The body of the scaffold.
  final Widget body;

  /// The navigation destinations.
  final List<AdaptiveNavigationDestination> destinations;

  /// The current selected index.
  final int selectedIndex;

  /// Callback when navigation item is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Whether to show the navigation rail (tablet/desktop).
  final bool showNavigationRail;

  /// Extended label behavior for navigation rail.
  final bool extendedNavRail;

  /// Constructor.
  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.floatingActionButton,
    this.showNavigationRail = true,
    this.extendedNavRail = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showNavigationRail || context.isPhone) {
      return _buildPhoneLayout();
    }
    return _buildTabletDesktopLayout(context);
  }

  Widget _buildPhoneLayout() {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        destinations: destinations.map((d) => d.toNavigationDestination()).toList(),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildTabletDesktopLayout(BuildContext context) {
    final isExtended = extendedNavRail && context.isDesktop;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: isExtended,
            backgroundColor: AppColors.background,
            indicatorColor: AppColors.primary.withValues(alpha: 0.1),
            labelType: isExtended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            leading: isExtended
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'MenuGreen',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
            destinations: destinations.map((d) => d.toNavigationRailDestination()).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// A data class representing a navigation destination.
class AdaptiveNavigationDestination {
  /// Icon for the destination.
  final IconData icon;

  /// Selected icon.
  final IconData? selectedIcon;

  /// Label text.
  final String label;

  /// Optional badge count.
  final int? badgeCount;

  /// Constructor.
  const AdaptiveNavigationDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badgeCount,
  });

  /// Converts to NavigationDestination.
  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: _buildIcon(),
      selectedIcon: _buildSelectedIcon(),
      label: label,
    );
  }

  /// Converts to NavigationRailDestination.
  NavigationRailDestination toNavigationRailDestination() {
    return NavigationRailDestination(
      icon: _buildIcon(),
      selectedIcon: _buildSelectedIcon(),
      label: Text(label),
    );
  }

  Widget _buildIcon() {
    if (badgeCount != null && badgeCount! > 0) {
      return Badge(
        label: Text(badgeCount.toString()),
        child: Icon(icon),
      );
    }
    return Icon(icon);
  }

  Widget? _buildSelectedIcon() {
    if (selectedIcon == null) return null;
    if (badgeCount != null && badgeCount! > 0) {
      return Badge(
        label: Text(badgeCount.toString()),
        child: Icon(selectedIcon),
      );
    }
    return Icon(selectedIcon);
  }
}
