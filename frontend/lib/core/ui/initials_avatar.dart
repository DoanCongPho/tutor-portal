import 'package:flutter/material.dart';

/// Circular avatar showing a person's initials over a soft brand tint — the
/// "NM" / "MA" badges used throughout the parent screens. Defaults read from the
/// theme so it stays on-brand without hardcoded colors.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.background,
    this.foreground,
  });

  final String name;
  final double radius;
  final Color? background;
  final Color? foreground;

  /// Vietnamese names put the given name last, so the initials are the first
  /// letters of the last two words (e.g. "Nguyễn Minh Anh" → "MA"), or the
  /// single word's first letter for one-word names.
  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    final a = parts[parts.length - 2].characters.first;
    final b = parts.last.characters.first;
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? scheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          color: foreground ?? scheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
