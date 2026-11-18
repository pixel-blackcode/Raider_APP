import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/messages/data/messaging_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'rider_nav_bar.dart';

/// Structure principale avec la barre de navigation flottante à cinq onglets.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadTotalProvider);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: RiderNavBar(
        key: const Key('app-nav'),
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          // Un second appui sur l'onglet actif revient à sa racine.
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          RiderNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: l10n.navHome,
          ),
          RiderNavItem(
            icon: Icons.route_outlined,
            selectedIcon: Icons.route,
            label: l10n.navRides,
          ),
          RiderNavItem(
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups,
            label: l10n.navClubs,
          ),
          RiderNavItem(
            icon: Icons.chat_bubble_outline,
            selectedIcon: Icons.chat_bubble,
            label: l10n.navMessages,
            badge: unread,
            badgeKey: const Key('nav-unread-badge'),
          ),
          RiderNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
