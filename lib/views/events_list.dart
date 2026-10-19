import 'package:flutter/material.dart';

import '../core/theme/custom_colors.dart';
import '../core/theme/custom_text_styles.dart';
import '../core/widgets/page_header.dart';

/// Minimal event shape used to render the Events list while the real Supabase
/// fetch is not wired up yet. Named `EventItem` to avoid clashing with the
/// generated `Event` model in `lib/models/event.dart`.
class EventItem {
  const EventItem({
    required this.name,
    required this.date,
    required this.time,
    required this.location,
    this.attendees = const [],
    this.photoCount = 0,
  });

  /// Event title, e.g. "Apéro des voisins".
  final String name;

  /// Scheduled date; only its month and day are shown.
  final DateTime date;

  /// French formatted start time, e.g. "18h30".
  final String time;

  /// Short place label shown next to the time.
  final String location;

  /// Display names of the people attending (used for avatar initials).
  final List<String> attendees;

  /// Number of photos already uploaded to a past event.
  final int photoCount;

  /// Whether the event happens after [now].
  bool isUpcoming(DateTime now) => date.isAfter(now);
}

/// French month abbreviations, indexed by `DateTime.month - 1`.
///
/// Hard-coded so the page does not depend on `intl` locale initialisation.
const List<String> _monthsFr = [
  'JANV.',
  'FÉVR.',
  'MARS',
  'AVR.',
  'MAI',
  'JUIN',
  'JUIL.',
  'AOÛT',
  'SEPT.',
  'OCT.',
  'NOV.',
  'DÉC.',
];

/// Placeholder events, expressed relative to "now" so the upcoming/past split
/// stays correct no matter when the app is run.
List<EventItem> _placeholderEvents() {
  final now = DateTime.now();
  return [
    EventItem(
      name: 'Apéro des voisins',
      date: now.add(const Duration(days: 2)),
      time: '18h30',
      location: 'Café de la Gare',
      attendees: const ['Léa', 'Tom', 'Inès', 'Marc', 'Sofia'],
    ),
    EventItem(
      name: 'Randonnée au coucher du soleil',
      date: now.add(const Duration(days: 5)),
      time: '17h00',
      location: 'Parc de Sceaux',
      attendees: const ['Hugo', 'Camille', 'Yanis', 'Alice'],
    ),
    EventItem(
      name: 'Soirée jeux de société',
      date: now.add(const Duration(days: 9)),
      time: '20h00',
      location: 'La Réserve aux Jeux',
      attendees: const ['Nina', 'Paul', 'Chloé'],
    ),
    EventItem(
      name: 'Brunch dominical',
      date: now.add(const Duration(days: 16)),
      time: '11h30',
      location: 'Maison Rose',
      attendees: const ['Emma', 'Lucas', 'Jade', 'Noah', 'Milo', 'Anna'],
    ),
    EventItem(
      name: 'Concert acoustique',
      date: now.subtract(const Duration(days: 3)),
      time: '21h00',
      location: 'Le Rockstore',
      attendees: const ['Lou', 'Théo', 'Manon'],
      photoCount: 12,
    ),
    EventItem(
      name: 'Atelier céramique',
      date: now.subtract(const Duration(days: 8)),
      time: '14h00',
      location: 'Studio Argile',
      attendees: const ['Sarah', 'Enzo'],
      photoCount: 6,
    ),
    EventItem(
      name: 'Course cycliste urbaine',
      date: now.subtract(const Duration(days: 15)),
      time: '9h30',
      location: 'Buttes-Chaumont',
      attendees: const ['Max', 'Lina', 'Omar', 'Zoe'],
      photoCount: 23,
    ),
    EventItem(
      name: 'Visite du vieux port',
      date: now.subtract(const Duration(days: 24)),
      time: '10h00',
      location: 'Vieux-Port',
      attendees: const ['Eva', 'Nils'],
      photoCount: 4,
    ),
  ];
}

/// Muted avatar tints that read well on both the light and dark card colour.
const List<Color> _avatarPalette = [
  Color(0xFFC77D51),
  Color(0xFF8A9A7B),
  Color(0xFF7C8AA0),
  Color(0xFFB08B9E),
  Color(0xFFA88B5C),
];

/// Events tab: an orange header over a scrollable, sectioned list of
/// upcoming and past events.
///
/// All colours and text styles come from the [CustomColors] and
/// [CustomTextStyles] theme extensions, so light and dark mode are handled by
/// the active theme with no branching here.
class EventsList extends StatelessWidget {
  const EventsList({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final textStyles = Theme.of(context).extension<CustomTextStyles>()!;

    final now = DateTime.now();
    final events = _placeholderEvents();
    final upcoming = events.where((e) => e.isUpcoming(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = events.where((e) => !e.isUpcoming(now)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: Column(
        children: [
          const PageHeader(title: 'Événements'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionTitle(
                    label: 'À VENIR',
                    textStyles: textStyles,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < upcoming.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _EventRow(
                      event: upcoming[i],
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],
                ],
                if (upcoming.isNotEmpty && past.isNotEmpty)
                  const SizedBox(height: 20),
                if (past.isNotEmpty) ...[
                  _SectionTitle(
                    label: 'PASSÉS',
                    textStyles: textStyles,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < past.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _EventRow(
                      event: past[i],
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase Outfit section heading ("À VENIR", "PASSÉS").
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.textStyles,
    required this.colors,
  });

  final String label;
  final CustomTextStyles textStyles;
  final CustomColors colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: textStyles.legendStyle.copyWith(
          color: colors.secondaryTextColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// One full-width clickable event row: a fixed-width date block plus a flexible
/// information card.
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.colors,
    required this.textStyles,
  });

  final EventItem event;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    final upcoming = event.isUpcoming(DateTime.now());

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/events/placeholder'),
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DateBlock(
              date: event.date,
              upcoming: upcoming,
              colors: colors,
              textStyles: textStyles,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                event: event,
                upcoming: upcoming,
                colors: colors,
                textStyles: textStyles,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed 48px-wide rounded date block. Upcoming events are solid orange with
/// white text; past events use the muted secondary surface.
class _DateBlock extends StatelessWidget {
  const _DateBlock({
    required this.date,
    required this.upcoming,
    required this.colors,
    required this.textStyles,
  });

  final DateTime date;
  final bool upcoming;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    final background = upcoming
        ? colors.accentColor
        : colors.secondarySurfaceColor;
    final foreground = upcoming ? Colors.white : colors.secondaryTextColor;

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _monthsFr[date.month - 1],
            textAlign: TextAlign.center,
            style: textStyles.legendStyle.copyWith(color: foreground),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            textAlign: TextAlign.center,
            style: textStyles.mainTitleStyle.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// Flexible rounded information card: title, meta line and attendee avatars,
/// with a trailing chevron (upcoming) or photo indicator (past).
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.event,
    required this.upcoming,
    required this.colors,
    required this.textStyles,
  });

  final EventItem event;
  final bool upcoming;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.subTitleStyle.copyWith(
                    color: colors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.time} · ${event.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.labelStyle.copyWith(
                    color: colors.secondaryTextColor,
                  ),
                ),
                if (event.attendees.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _AvatarRow(
                    names: event.attendees,
                    ringColor: colors.cardColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TrailingIndicator(
            upcoming: upcoming,
            photoCount: event.photoCount,
            colors: colors,
            textStyles: textStyles,
          ),
        ],
      ),
    );
  }
}

/// Up to four overlapping 18px circular avatars drawn from attendee initials.
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.names, required this.ringColor});

  final List<String> names;
  final Color ringColor;

  static const double _size = 18;
  static const double _overlapStep = 12;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(4).toList();

    return SizedBox(
      height: _size,
      width: _size + (shown.length - 1) * _overlapStep,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _overlapStep,
              child: _Avatar(name: shown[i], index: i, ringColor: ringColor),
            ),
        ],
      ),
    );
  }
}

/// A single 18px circle showing an attendee's initial.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.index,
    required this.ringColor,
  });

  final String name;
  final int index;
  final Color ringColor;

  static const double _size = 18;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _avatarPalette[index % _avatarPalette.length],
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

/// Orange chevron for upcoming events, small photo indicator for past ones.
class _TrailingIndicator extends StatelessWidget {
  const _TrailingIndicator({
    required this.upcoming,
    required this.photoCount,
    required this.colors,
    required this.textStyles,
  });

  final bool upcoming;
  final int photoCount;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    if (upcoming) {
      return Icon(Icons.chevron_right, size: 22, color: colors.accentColor);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_outlined, size: 16, color: colors.secondaryTextColor),
        if (photoCount > 0) ...[
          const SizedBox(height: 2),
          Text(
            '$photoCount',
            style: textStyles.legendStyle.copyWith(
              color: colors.secondaryTextColor,
            ),
          ),
        ],
      ],
    );
  }
}
