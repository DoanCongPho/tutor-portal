import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'role_nav_shell.dart';

/// Bottom-nav shell for the tutor role — Home · Schedule · Students · Wallet ·
/// Profile (the "Component / BottomNav / Tutor" mockup). Differs from the parent
/// shell by swapping Search→Schedule and Bookings→Students.
class TutorShell extends StatelessWidget {
  const TutorShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <RoleNavItem>[
    RoleNavItem(Icons.home_outlined, Icons.home, 'Home'),
    RoleNavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Schedule'),
    RoleNavItem(Icons.people_outline, Icons.people, 'Students'),
    RoleNavItem(
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      'Wallet',
    ),
    RoleNavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) =>
      RoleNavShell(navigationShell: navigationShell, items: _items);
}
