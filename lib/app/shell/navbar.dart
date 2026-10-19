import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_themes.dart';
import '../../core/theme/custom_colors.dart';

/// The four primary tabs of the app, in display order.
///
/// Each tab maps to a custom 24×24 outline SVG in `assets/icons/`. The icons
/// are drawn with `stroke="currentColor"` and no fill, so the active and
/// inactive states are produced purely by recoloring the same asset.
enum NavTab {
  events('Events', 'assets/icons/events.svg'),
  map('Map', 'assets/icons/map.svg'),
  messages('Messages', 'assets/icons/messages.svg'),
  profile('Profile', 'assets/icons/profile.svg');

  const NavTab(this.label, this.asset);

  /// Accessibility label; the icon itself carries no visible text.
  final String label;

  /// Path to the outline SVG asset.
  final String asset;
}

/// The app's bottom navigation bar.
///
/// Full-width row of four equal-width, icon-only tabs with a 1px top border.
/// There are deliberately no labels, background circles, active pills or
/// underline — the active tab is indicated by colour alone.
class Navbar extends StatelessWidget {
  const Navbar({super.key, required this.currentIndex, required this.onTap});

  /// Index of the currently selected [NavTab].
  final int currentIndex;

  /// Called with the tapped tab index.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>();
    final activeColor = colors?.accentColor ?? AppThemes.primaryBrand;
    final inactiveColor = colors?.secondaryTextColor ?? Colors.grey;
    final backgroundColor = colors?.mainBackgroundColor ?? Colors.white;
    final borderColor = colors?.borderColor ?? Colors.transparent;

    // Keep the bar's contents clear of the system navigation bar (the gesture
    // pill or the taller three-button bar). The app draws edge-to-edge, so
    // without this the icons sit underneath the system bar — overlapped on
    // gesture-navigation phones and fully hidden on three-button ones.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      // Padding sits inside the DecoratedBox so the background and top border
      // still fill the area behind the system bar; only the icons move up.
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Row(
          children: [
            for (var index = 0; index < NavTab.values.length; index++)
              Expanded(
                child: _NavTabButton(
                  tab: NavTab.values[index],
                  isActive: index == currentIndex,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onTap(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single icon-only tab button.
class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.tab,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final NavTab tab;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tab.label,
      selected: isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          // A one-child Row centres the icon horizontally while sizing to the
          // icon vertically. `Center` would instead expand to fill the bounded
          // height Scaffold hands a bottomNavigationBar, stretching the bar to
          // the full screen height.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                tab.asset,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isActive ? activeColor : inactiveColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
