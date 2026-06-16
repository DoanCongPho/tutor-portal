import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'role_nav_shell.dart';

/// Bottom-nav shell for the student role — Home · Materials · Tasks · Profile
/// (the "Component / BottomNav / Student" mockup). Only four tabs: students get
/// no Search/Wallet, but a Materials and Tasks tab the other roles don't have.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <RoleNavItem>[
    RoleNavItem(Icons.home_outlined, Icons.home, 'Home'),
    RoleNavItem(Icons.menu_book_outlined, Icons.menu_book, 'Materials'),
    RoleNavItem(Icons.assignment_outlined, Icons.assignment, 'Tasks'),
    RoleNavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) =>
      RoleNavShell(navigationShell: navigationShell, items: _items);
}
