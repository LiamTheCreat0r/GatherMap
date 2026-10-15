import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/theme/custom_colors.dart';
import 'loading_dots.dart';

/// Map tab.
///
/// Like most map plugins, MapLibre builds its style asynchronously: a map that
/// exists is not yet a map whose style is loaded. Sources and layers can only
/// be added once the style is ready, so they are added from
/// [MapLibreMap.onStyleLoadedCallback] — not from `onMapCreated`, which fires
/// while the style is still null and makes the plugin throw `STYLE_NOT_READY`.
///
/// Until the style is ready the map is covered by a [LoadingDots] overlay so
/// the user sees the app's loader instead of a blank platform view. The
/// overlay fades out once the style (and the demo marker) is in place.
class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  /// Kept from `onMapCreated` so the style callback can drive the map.
  MapLibreMapController? _controller;

  /// Drives the loading overlay; flipped once the style has loaded and the
  /// map's sources have been added.
  bool _isStyleLoaded = false;

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null || _isStyleLoaded) return;

    await controller.addGeoJsonSource('IUT', {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'id': 'f1', // optional, needed for setGeoJsonFeature()
          'properties': {'name': 'IUT Toulouse', 'country': 'France'},
          'geometry': {
            'type': 'Point',
            'coordinates': [1.46480387, 43.5703174], // [lng, lat]
          },
        },
      ],
    });
    await controller.addSymbolLayer(
      'IUT',
      'IUT-layer',
      const SymbolLayerProperties(
        //iconImage: 'my-marker',
        iconSize: 1.0,
        iconAnchor: 'bottom',
        iconAllowOverlap: true,
        textField: [Expressions.get, 'name'],
        textSize: 13,
        textOffset: [0, 1.2],
        textAnchor: 'top',
        textHaloColor: '#ffffff',
        textHaloWidth: 2,
      ),
    );

    if (mounted) setState(() => _isStyleLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;

    return Stack(
      children: [
        MapLibreMap(
          onMapCreated: (MapLibreMapController controller) =>
              _controller = controller,
          onStyleLoadedCallback: _onStyleLoaded,
          initialCameraPosition: const CameraPosition(
            target: LatLng(43.57, 1.464),
            zoom: 12,
          ),
          styleString:
              'https://api.maptiler.com/maps/01a1343d-e0c3-7e05-93c1-743d65f9b644/style.json?key=nHhdC9Q6mdTwQ6qo9eiV',
        ),
        // Opaque overlay covers the blank map until the style is ready, then
        // fades out. [IgnorePointer] releases taps as soon as loading ends so
        // the map underneath is interactive during the fade.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _isStyleLoaded,
            child: AnimatedOpacity(
              opacity: _isStyleLoaded ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: Container(
                color: colors.mainBackgroundColor,
                alignment: Alignment.center,
                child: LoadingDots(color: colors.accentColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
