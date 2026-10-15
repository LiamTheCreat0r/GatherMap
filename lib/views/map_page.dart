import 'package:flutter/material.dart';

import '../core/theme/custom_colors.dart';
import 'widgets/create_event_dialog.dart';
import 'widgets/map_widget.dart';
import 'widgets/page_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: Column(
        children: [
          PageHeader(
            title: 'Carte',
            trailing: VisibilityToggle(
              value: _visibility,
              onChanged: (value) => setState(() => _visibility = value),
            ),
          ),
          const Expanded(child: Map()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showCreateEventDialog(context);
          if (!context.mounted || created == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Événement créé')),
          );
        },
        backgroundColor: colors.accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Créer un événement'),
      ),
    );
  }
}
