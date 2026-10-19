import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';

/// Who an event on the map is visible to.
enum MapVisibility {
  friends('Amis'),
  public('Public');

  const MapVisibility(this.label);

  /// French label shown inside the toggle.
  final String label;
}

/// Compact two-segment pill for switching between [MapVisibility] values.
///
/// Designed to sit in the orange [PageHeader] `trailing` slot: the selected
/// segment is a solid white pill with accent-coloured text, while the
/// unselected segment is transparent with white text so it reads against the
/// header. Colours come from the [CustomColors] theme extension, so light and
/// dark mode are handled by the active theme with no branching here.
class VisibilityToggle extends StatelessWidget {
  const VisibilityToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Currently selected visibility.
  final MapVisibility value;

  /// Called with the newly tapped visibility.
  final ValueChanged<MapVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in MapVisibility.values)
              _Segment(
                label: option.label,
                isSelected: option == value,
                colors: colors,
                onTap: () => onChanged(option),
              ),
          ],
        ),
      ),
    );
  }
}

/// One tappable segment of the [VisibilityToggle].
class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final CustomColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? colors.accentColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
