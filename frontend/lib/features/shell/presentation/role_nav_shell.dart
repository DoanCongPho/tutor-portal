import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A single bottom-nav destination: an outline + filled icon pair and a label.
class RoleNavItem {
  const RoleNavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Generic bottom-nav shell shared by the per-role shells (parent has its own
/// historical copy). Hosts a [StatefulNavigationShell] — one navigator per tab,
/// so each tab keeps its own back stack and switching preserves scroll position.
///
/// The three roles differ only in their [items]: Parent (Home · Search ·
/// Bookings · Wallet · Profile), Tutor (Home · Schedule · Students · Wallet ·
/// Profile) and Student (Home · Materials · Tasks · Profile).
class RoleNavShell extends StatelessWidget {
  const RoleNavShell({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  final StatefulNavigationShell navigationShell;
  final List<RoleNavItem> items;

  void _onTap(int index) {
    // initialLocation: re-tapping the active tab pops it back to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      selected: i == navigationShell.currentIndex,
                      onTap: () => _onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final RoleNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.activeIcon : item.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
