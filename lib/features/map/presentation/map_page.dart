import 'package:flutter/material.dart';

import '../../../core/theme/custom_colors.dart';
import '../../../core/widgets/page_header.dart';
import '../../events/domain/event.dart';
import '../../events/presentation/widgets/create_event_dialog.dart';
import '../../events/presentation/widgets/event_detail_sheet.dart';
import 'widgets/map_widget.dart';
import 'widgets/visibility_toggle.dart';

/// Map tab: the orange [PageHeader] over the full-bleed [Map].
///
/// The header carries a [VisibilityToggle] that switches the map between
/// friends-only and public events, and a floating action button opens the
/// create-event window over the map. Colours come from the [CustomColors]
/// theme extension, so light and dark mode are handled by the active theme
/// with no branching here.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapVisibility _visibility = MapVisibility.friends;

  /// Event currently shown in the detail sheet, if any.
  ///
  /// Owned here rather than inside [Map] so the sheet can be stacked over the
  /// whole page — including the header and the create-event button — and can
  /// expand to the full body height.
  Event? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              PageHeader(
                title: 'Carte',
                trailing: VisibilityToggle(
                  value: _visibility,
                  onChanged: (value) => setState(() => _visibility = value),
                ),
              ),
              Expanded(
                child: Map(
                  selectedEvent: _selectedEvent,
                  onSelectedEventChanged: (event) {
                    setState(() => _selectedEvent = event);
                  },
                ),
              ),
            ],
          ),
          // Kept inside the same stack as the detail sheet and placed before
          // it, so an open sheet always covers the button instead of floating
          // above the event details.
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final created = await showCreateEventDialog(context);
                if (!context.mounted || created == null) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Événement créé')));
              },
              backgroundColor: colors.accentColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Créer un événement'),
            ),
          ),
          if (_selectedEvent != null)
            Positioned.fill(
              child: SafeArea(
                top: true,
                bottom: false,
                left: false,
                right: false,
                child: EventDetailSheet(
                  key: ValueKey('event-detail-${_selectedEvent!.id}'),
                  event: _selectedEvent!,
                  onClose: () => setState(() => _selectedEvent = null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
