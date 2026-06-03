import 'package:flutter/material.dart';

/// Lightweight "coming soon" scaffold for parent tabs that aren't built yet
/// (Search, Bookings, Wallet). Keeps the shell navigable end to end while those
/// features land. Mirrors the Shared / Empty State mockup.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        titleTextStyle: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, size: 40, color: scheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                '$title is coming soon',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Search',
        icon: Icons.search,
        message: 'Find and filter verified tutors by subject, level and price.',
      );
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Bookings',
        icon: Icons.calendar_today,
        message: 'Track your upcoming and past sessions here.',
      );
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Wallet',
        icon: Icons.account_balance_wallet,
        message: 'Top up, view your balance and review transactions.',
      );
}
