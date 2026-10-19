import 'package:flutter/material.dart';

/// Background colours cycled through for overlapping avatar circles.
///
/// Warm, low-saturation tones chosen to sit under white initials on either
/// theme; indexed by position so a list of names keeps stable colours.
const List<Color> avatarPalette = [
  Color(0xFFC77D51),
  Color(0xFF8A9A7B),
  Color(0xFF7C8AA0),
  Color(0xFFB08B9E),
  Color(0xFFA88B5C),
];

/// A single circular avatar showing the first letter of [name].
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    required this.index,
    required this.ringColor,
    this.size = 18,
  });

  /// Display name; only its first character is shown.
  final String name;

  /// Position in the owning row, used to pick a colour from [avatarPalette].
  final int index;

  /// Colour of the thin border separating overlapping avatars.
  final Color ringColor;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatarPalette[index % avatarPalette.length],
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1.5),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

/// Up to four overlapping [Avatar]s drawn from display names.
class AvatarRow extends StatelessWidget {
  const AvatarRow({
    super.key,
    required this.names,
    required this.ringColor,
    this.size = 18,
  });

  /// Display names to draw, in order; only the first four are shown.
  final List<String> names;

  /// Colour of the border separating overlapping avatars.
  final Color ringColor;

  /// Diameter of each circle in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(4).toList();
    final overlapStep = size * 2 / 3;

    return SizedBox(
      height: size,
      width: size + (shown.length - 1) * overlapStep,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlapStep,
              child: Avatar(
                name: shown[i],
                index: i,
                ringColor: ringColor,
                size: size,
              ),
            ),
        ],
      ),
    );
  }
}
