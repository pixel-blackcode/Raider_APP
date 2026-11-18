import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class RiderNavItem {
  const RiderNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
    this.badgeKey,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badge;
  final Key? badgeKey;
}

/// Barre de navigation flottante (catalogue N4) : carte arrondie détachée
/// des bords, onglet actif dans une pilule marine qui glisse avec un léger
/// rebond (simple fondu si les animations sont réduites).
class RiderNavBar extends StatelessWidget {
  const RiderNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RiderNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduce = MediaQuery.of(context).disableAnimations;
    final pillColor = isDark ? theme.colorScheme.primary : AppColors.marine;
    final onPill = isDark ? theme.colorScheme.onPrimary : Colors.white;
    final idle = theme.colorScheme.onSurfaceVariant;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xF2182644) : const Color(0xF7FFFFFF),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: isDark ? const Color(0x1FFFFFFF) : Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.marine.withValues(alpha: isDark ? 0.4 : 0.14),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth / items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: Duration(milliseconds: reduce ? 0 : 380),
                  curve: Curves.easeOutBack,
                  left: w * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: i == selectedIndex,
                          color: i == selectedIndex ? onPill : idle,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final RiderNavItem item;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget icon = Icon(
      selected ? item.selectedIcon : item.icon,
      color: color,
      size: 24,
    );
    if (item.badgeKey != null) {
      icon = Badge(
        key: item.badgeKey,
        isLabelVisible: item.badge > 0,
        label: Text('${item.badge}'),
        child: icon,
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
