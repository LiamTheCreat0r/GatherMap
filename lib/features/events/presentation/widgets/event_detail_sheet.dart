import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_themes.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../../../core/theme/custom_text_styles.dart';
import '../../../../core/widgets/avatar_row.dart';
import '../../../../core/widgets/loading_dots.dart';
import '../../domain/event.dart';
import '../../domain/event_guest.dart';
import '../event_formatters.dart';
import '../event_guest_controller.dart';

/// The tabs of the event detail sheet, in display order.
enum _DetailTab { overview, guests, chat, bring, photos }

extension on _DetailTab {
  String get label => switch (this) {
    _DetailTab.overview => 'APERÇU',
    _DetailTab.guests => 'INVITÉS',
    _DetailTab.chat => 'CHAT',
    _DetailTab.bring => 'APPORTER',
    _DetailTab.photos => 'PHOTOS',
  };

  IconData get icon => switch (this) {
    _DetailTab.overview => Icons.description_outlined,
    _DetailTab.guests => Icons.group_outlined,
    _DetailTab.chat => Icons.chat_bubble_outline,
    _DetailTab.bring => Icons.shopping_bag_outlined,
    _DetailTab.photos => Icons.photo_camera_outlined,
  };
}

/// Google Maps-style bottom panel for one event.
///
/// Non-modal: it is placed in the map page's `Stack`, above the map, header and
/// create-event button, so the map remains interactive behind it. It starts
/// compact (title, date, RSVP counts and the action bar) and drags up to fill
/// the page body, revealing the tabbed detail content.
class EventDetailSheet extends StatefulWidget {
  const EventDetailSheet({
    super.key,
    required this.event,
    required this.onClose,
  });

  /// The event whose details are shown.
  final Event event;

  /// Closes the sheet; the map clears its selected event.
  final VoidCallback onClose;

  @override
  State<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<EventDetailSheet> {
  static const double _compactSize = 0.36;
  static const double _expandedSize = 1;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  _DetailTab _activeTab = _DetailTab.overview;

  /// Guards against scheduling more than one close while a downward drag
  /// keeps emitting size notifications.
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    // Deferred so the controller's loading notification lands after this build
    // rather than during it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EventGuestController>().loadFor(widget.event);
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _selectTab(_DetailTab tab) {
    setState(() => _activeTab = tab);
    final controller = _sheetController;
    if (controller.isAttached && controller.size < 0.6) {
      controller.animateTo(
        _expandedSize,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Closes the sheet once a downward drag reaches the minimum extent.
  ///
  /// [DraggableScrollableSheet] only emits the notification; it does not know
  /// how to dismiss its host, so the page removes the sheet here.
  void _handleSheetNotification(DraggableScrollableNotification notification) {
    if (!notification.shouldCloseOnMinExtent) return;
    if (notification.extent > notification.minExtent + 0.001) return;
    if (_isDismissing) return;

    _isDismissing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final guestController = context.watch<EventGuestController>();
    final event = widget.event;
    final accent = eventColorFromHex(event.color, colors.accentColor);
    final isUpcoming = eventIsUpcoming(event.scheduledAt);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        _handleSheetNotification(notification);
        return false;
      },
      child: DraggableScrollableSheet(
        key: const ValueKey('event-detail-sheet'),
        controller: _sheetController,
        initialChildSize: _compactSize,
        minChildSize: 0.18,
        maxChildSize: _expandedSize,
        snap: true,
        snapSizes: const [_compactSize, _expandedSize],
        builder: (context, scrollController) {
          return DecoratedBox(
            key: const ValueKey('event-detail-panel'),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border(top: BorderSide(color: colors.borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    key: const ValueKey('event-detail-scroll'),
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      const _DragHandle(),
                      _CompactHeader(
                        event: event,
                        accent: accent,
                        isUpcoming: isUpcoming,
                        organizer: guestController.organizer,
                        onClose: widget.onClose,
                      ),
                      _RsvpChips(
                        attending: guestController.attending,
                        declined: guestController.declined,
                      ),
                      _TabStrip(
                        active: _activeTab,
                        accent: accent,
                        onSelected: _selectTab,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _buildTab(
                          guestController,
                          accent: accent,
                          colors: colors,
                          textStyles: textStyles,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _RsvpActionBar(onAttend: () {}, onDecline: () {}),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(
    EventGuestController controller, {
    required Color accent,
    required CustomColors colors,
    required CustomTextStyles textStyles,
  }) {
    return switch (_activeTab) {
      _DetailTab.overview => _OverviewTab(
        event: widget.event,
        accent: accent,
        colors: colors,
        textStyles: textStyles,
      ),
      _DetailTab.guests => _GuestsTab(
        controller: controller,
        accent: accent,
        colors: colors,
        textStyles: textStyles,
      ),
      _DetailTab.chat => _EmptyTab(
        icon: Icons.chat_bubble_outline,
        title: 'Aucun message',
        message: 'Le chat de l’événement sera disponible ici.',
        colors: colors,
        textStyles: textStyles,
      ),
      _DetailTab.bring => _EmptyTab(
        icon: Icons.shopping_bag_outlined,
        title: 'Aucune liste',
        message: 'Les objets à apporter ne sont pas encore disponibles.',
        colors: colors,
        textStyles: textStyles,
      ),
      _DetailTab.photos => _EmptyTab(
        icon: Icons.photo_camera_outlined,
        title: 'Aucune photo',
        message: 'Les photos partagées apparaîtront ici.',
        colors: colors,
        textStyles: textStyles,
      ),
    };
  }
}

/// Small centred grabber at the top of the sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: colors.borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Compact, always-visible row: emoji, title, status, date and organiser.
class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.event,
    required this.accent,
    required this.isUpcoming,
    required this.organizer,
    required this.onClose,
  });

  final Event event;
  final Color accent;
  final bool isUpcoming;
  final EventPerson? organizer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Text(
              event.emojiIcon.isEmpty ? '📅' : event.emojiIcon,
              style: const TextStyle(fontSize: 24, height: 1.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.mainTitleStyle.copyWith(
                          color: colors.primaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(isUpcoming: isUpcoming, accent: accent),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  formatEventShortDate(event.scheduledAt),
                  style: textStyles.labelStyle.copyWith(
                    color: colors.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: colors.secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.labelStyle.copyWith(
                          color: colors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (organizer != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Avatar(
                        name: organizer!.displayName,
                        index: 0,
                        ringColor: colors.cardColor,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'organisé par ',
                                style: textStyles.legendStyle.copyWith(
                                  color: colors.secondaryTextColor,
                                ),
                              ),
                              TextSpan(
                                text: organizer!.displayName,
                                style: textStyles.labelStyle.copyWith(
                                  color: colors.primaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('event-detail-close'),
            onPressed: onClose,
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            color: colors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

/// `À venir` / `Passé` pill.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isUpcoming, required this.accent});

  final bool isUpcoming;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final color = isUpcoming ? accent : colors.secondaryTextColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        isUpcoming ? 'À venir' : 'Passé',
        style: textStyles.legendStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Two RSVP count pills backed by the real invitation rows.
class _RsvpChips extends StatelessWidget {
  const _RsvpChips({required this.attending, required this.declined});

  final int attending;
  final int declined;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _RsvpChip(
              count: attending,
              label: 'présents',
              color: colors.successColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RsvpChip(
              count: declined,
              label: 'absents',
              color: colors.dangerColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RsvpChip extends StatelessWidget {
  const _RsvpChip({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$count',
              style: textStyles.labelStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: ' $label',
              style: textStyles.legendStyle.copyWith(
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Icon-above-label tab strip with an orange underline for the active tab.
class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.active,
    required this.accent,
    required this.onSelected,
  });

  final _DetailTab active;
  final Color accent;
  final ValueChanged<_DetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.borderColor)),
        ),
        child: Row(
          children: [
            for (final tab in _DetailTab.values)
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(tab),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 20,
                          color: tab == active
                              ? accent
                              : colors.secondaryTextColor,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            style: context.textStyles.legendStyle.copyWith(
                              color: tab == active
                                  ? accent
                                  : colors.secondaryTextColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 2,
                          width: tab == active ? 26 : 0,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Overview tab: hero block, about, location and model-derived details.
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.event,
    required this.accent,
    required this.colors,
    required this.textStyles,
  });

  final Event event;
  final Color accent;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    final createdAt = event.createdAt;
    final hasCreatedAt = createdAt != null && createdAt.year > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(event: event, accent: accent, colors: colors),
        const SizedBox(height: 14),
        _SectionCard(
          label: 'À PROPOS',
          colors: colors,
          textStyles: textStyles,
          child: Text(
            'Aucune description pour cet événement.',
            style: textStyles.bodyTextStyle.copyWith(
              color: colors.secondaryTextColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          label: 'LIEU',
          colors: colors,
          textStyles: textStyles,
          child: Row(
            children: [
              Icon(Icons.place_outlined, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.location,
                  style: textStyles.bodyTextStyle.copyWith(
                    color: colors.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          label: 'DÉTAILS',
          colors: colors,
          textStyles: textStyles,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Quand',
                value: formatEventLongDate(event.scheduledAt),
                colors: colors,
                textStyles: textStyles,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: event.isPublic ? Icons.public : Icons.lock_outline,
                label: 'Visibilité',
                value: event.isPublic ? 'Public' : 'Privé',
                colors: colors,
                textStyles: textStyles,
              ),
              if (hasCreatedAt) ...[
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.edit_calendar_outlined,
                  label: 'Créé le',
                  value: formatEventShortDate(createdAt),
                  colors: colors,
                  textStyles: textStyles,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Colour-tinted banner that stands in for a hero photo until events carry one.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.event,
    required this.accent,
    required this.colors,
  });

  final Event event;
  final Color accent;
  final CustomColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.55),
            colors.secondarySurfaceColor,
          ],
        ),
      ),
      child: Text(
        event.emojiIcon.isEmpty ? '📅' : event.emojiIcon,
        style: const TextStyle(fontSize: 56, height: 1.2),
      ),
    );
  }
}

/// Rounded card with a small uppercase label above its content.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.child,
    required this.colors,
    required this.textStyles,
  });

  final String label;
  final Widget child;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondarySurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textStyles.legendStyle.copyWith(
              color: colors.secondaryTextColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.textStyles,
  });

  final IconData icon;
  final String label;
  final String value;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.secondaryTextColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: textStyles.labelStyle.copyWith(
              color: colors.secondaryTextColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textStyles.bodyTextStyle.copyWith(
              color: colors.primaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Guests tab: real invitation rows grouped by answer.
class _GuestsTab extends StatelessWidget {
  const _GuestsTab({
    required this.controller,
    required this.accent,
    required this.colors,
    required this.textStyles,
  });

  final EventGuestController controller;
  final Color accent;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.guests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(child: LoadingDots(color: accent)),
      );
    }

    if (controller.hasError) {
      return _InlineMessage(
        icon: Icons.error_outline,
        message: controller.error ?? 'Impossible de charger les invités.',
        color: colors.dangerColor,
        colors: colors,
        textStyles: textStyles,
      );
    }

    if (controller.guests.isEmpty) {
      return _InlineMessage(
        icon: Icons.group_outlined,
        message: 'Les invitations apparaîtront ici.',
        color: colors.secondaryTextColor,
        colors: colors,
        textStyles: textStyles,
      );
    }

    final guests = [...controller.guests]
      ..sort((a, b) {
        int rank(bool? accepted) => switch (accepted) {
          true => 0,
          null => 1,
          false => 2,
        };
        return rank(a.accepted).compareTo(rank(b.accepted));
      });

    return Column(
      children: [
        for (final guest in guests) ...[
          _GuestRow(guest: guest, colors: colors, textStyles: textStyles),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({
    required this.guest,
    required this.colors,
    required this.textStyles,
  });

  final EventGuest guest;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (guest.accepted) {
      true => ('Présent', colors.successColor),
      null => ('En attente', colors.warningColor),
      false => ('Absent', colors.dangerColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondarySurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Avatar(
            name: guest.person.displayName,
            index: guest.person.id.hashCode,
            ringColor: colors.secondarySurfaceColor,
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.person.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.subTitleStyle.copyWith(
                    color: colors.primaryTextColor,
                    fontSize: 14,
                  ),
                ),
                if (guest.person.username.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    '@${guest.person.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyles.labelStyle.copyWith(
                      color: colors.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              label,
              style: textStyles.legendStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centred empty/error state shared by the guest and placeholder tabs.
class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.message,
    required this.color,
    required this.colors,
    required this.textStyles,
  });

  final IconData icon;
  final String message;
  final Color color;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: colors.secondarySurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textStyles.bodyTextStyle.copyWith(
              color: colors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Styled placeholder for tabs whose data is not stored yet.
class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.message,
    required this.colors,
    required this.textStyles,
  });

  final IconData icon;
  final String title;
  final String message;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: colors.secondarySurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: colors.accentColor),
          const SizedBox(height: 10),
          Text(
            title,
            style: textStyles.subTitleStyle.copyWith(
              color: colors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textStyles.bodyTextStyle.copyWith(
              color: colors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom RSVP bar.
///
/// The callbacks are no-ops for now: there is no signed-in user or RSVP write
/// wired yet, but the controls are present so the layout is complete.
class _RsvpActionBar extends StatelessWidget {
  const _RsvpActionBar({required this.onAttend, required this.onDecline});

  final VoidCallback onAttend;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderColor)),
        color: colors.cardColor,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('rsvp-attend'),
                onPressed: onAttend,
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  'Je viens',
                  style: textStyles.actionStyle.copyWith(color: Colors.white),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('rsvp-decline'),
                onPressed: onDecline,
                icon: const Icon(Icons.close, size: 18),
                label: Text(
                  'Absent',
                  style: textStyles.actionStyle.copyWith(color: Colors.white),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.dangerColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
