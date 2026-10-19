import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../core/theme/custom_text_styles.dart';
import '../../../../core/widgets/loading_dots.dart';
import '../../../events/domain/event.dart';
import '../../../events/presentation/event_controller.dart';
import 'event_pin.dart';

/// GeoJSON source holding every pinned event as a point feature.
const String _eventsSourceId = 'event-pins';

/// Symbol layer drawing those points with the rendered pin images.
const String _eventsLayerId = 'event-pins-layer';

/// Map tab.
///
/// Like most map plugins, MapLibre builds its style asynchronously: a map that
/// exists is not yet a map whose style is loaded. Sources and layers can only
/// be added once the style is ready, so they are added from
/// [MapLibreMap.onStyleLoadedCallback] — not from `onMapCreated`, which fires
/// while the style is still null and makes the plugin throw `STYLE_NOT_READY`.
///
/// Events are drawn as native MapLibre symbols: each pin is rendered to a PNG
/// (see [renderEventPinPng]) and registered with [MapLibreMapController.addImage],
/// a GeoJSON point feature references it via its `icon` property, and a symbol
/// layer places `iconAnchor: 'bottom'` on the coordinate. MapLibre then keeps
/// the pins glued to their coordinates through every pan and zoom with no
/// Flutter-side projection.
///
/// Until the style is ready the map is covered by a [LoadingDots] overlay so
/// the user sees the app's loader instead of a blank platform view. The
/// overlay fades out once the style (and the pin images) are in place.
class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  /// Kept from `onMapCreated` so the style callback can drive the map.
  MapLibreMapController? _controller;

  /// Drives the loading overlay; flipped once the style has loaded.
  bool _isStyleLoaded = false;

  /// Events currently loaded, refreshed from the controller on every build.
  List<Event> _events = const [];

  /// True once the camera has been fitted to the pins. The fit runs a single
  /// time — on the first pinnable events after the style loads — so the view
  /// doesn't yank itself around every time the event list refreshes or the
  /// user pans away.
  bool _hasFitCamera = false;

  /// True while a pin sync is in flight, so overlapping triggers (style load
  /// + an event refresh landing together) queue into one pass.
  bool _syncing = false;

  /// Latest theme values captured during build, so the async sync can render
  /// pin bitmaps without touching `Theme.of` outside the build phase.
  CustomColors? _colors;
  CustomTextStyles? _textStyles;

  /// Device pixel ratio the pin bitmaps are rendered at — MapLibre registers
  /// images with the device pixel ratio as their pixel ratio (iOS passes
  /// `UIScreen.main.scale`), so the PNG must match it for correct sizing.
  double _devicePixelRatio = 1;

  /// Palette captured on the previous build, used to detect theme changes.
  Color? _accentBeforeBuild;
  Color? _cardBeforeBuild;

  @override
  void initState() {
    super.initState();
    // Load the events to pin as soon as the tab opens; the map renders them
    // as soon as the style is ready. Deferred a frame so the controller's
    // loading notification lands after this build rather than during it
    // (calling it synchronously here would notify mid-build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EventController>().fetchUpcoming();
    });
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null || _isStyleLoaded || !mounted) return;
    setState(() => _isStyleLoaded = true);

    // Sources and layers may only be created once the style is loaded — before
    // this point the plugin rejects every style call with STYLE_NOT_READY.
    await controller.addGeoJsonSource(_eventsSourceId, _emptyFeatureCollection);
    await controller.addSymbolLayer(
      _eventsSourceId,
      _eventsLayerId,
      SymbolLayerProperties(
        // Data-driven: each feature points at its own uploaded pin image.
        iconImage: [Expressions.get, 'icon'],
        // The PNG's bottom edge (the anchor dot's base) sits on the coordinate,
        // matching the FractionalTranslation(-0.5, -1) of the old overlay.
        iconAnchor: 'bottom',
        // Pins always render, even when several overlap — same as the overlay.
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );
    // The tab can be closed while those platform calls are in flight; a
    // disposed map must not be handed more work.
    if (!mounted || controller != _controller) return;
    await _syncPinsToMap();
    await _fitToPins();
  }

  // Typed by inference: this class is itself named `Map`, so an explicit
  // `Map<String, dynamic>` annotation would resolve to the widget.
  static const _emptyFeatureCollection = {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

  /// Events that can actually be pinned: they carry coordinates and an id to
  /// key their image by.
  List<Event> get _pinnableEvents =>
      _events.where((event) => event.isPinnable).toList();

  /// Renders each pinnable event's pin to a PNG, uploads it as a style image,
  /// and points the GeoJSON source at the matching features.
  ///
  /// Images are added before the source data so every feature's `icon` exists
  /// by the time the layer needs it — adding both in one frame can let the
  /// platform drop the freshly registered icon from the texture atlas.
  Future<void> _syncPinsToMap() async {
    final controller = _controller;
    final colors = _colors;
    final textStyles = _textStyles;
    if (controller == null ||
        colors == null ||
        textStyles == null ||
        !_isStyleLoaded ||
        _syncing) {
      return;
    }

    _syncing = true;
    try {
      // Collected as `dynamic` because `Map<String, dynamic>` would name this
      // widget class rather than the core collection type.
      final features = <dynamic>[];
      for (final event in _pinnableEvents) {
        final iconId = 'event-pin-${event.id}';
        final bytes = await renderEventPinPng(
          name: event.name,
          emoji: event.emojiIcon,
          colors: colors,
          textStyles: textStyles,
          devicePixelRatio: _devicePixelRatio,
        );
        // The map or the events may have been replaced mid-render; the
        // successor's own sync will handle the current state.
        if (!mounted || controller != _controller) return;

        await controller.addImage(iconId, bytes);
        features.add({
          'type': 'Feature',
          'properties': {'icon': iconId, 'name': event.name},
          'geometry': {
            'type': 'Point',
            'coordinates': [event.longitude!, event.latitude!],
          },
        });
      }

      if (!mounted || controller != _controller) return;
      await controller.setGeoJsonSource(_eventsSourceId, {
        'type': 'FeatureCollection',
        'features': features,
      });
    } finally {
      _syncing = false;
    }
  }

  /// Frames the camera around every pinnable event, once, after the style is
  /// ready and events have loaded.
  ///
  /// With several events the camera fits their bounding box (inset by
  /// [padding] so pins aren't flush to the edges). A lone event can't use the
  /// bounds API — a zero-size box zooms to the maximum — so it falls back to a
  /// fixed street-level zoom on that point instead.
  Future<void> _fitToPins() async {
    final controller = _controller;
    if (controller == null || !_isStyleLoaded || _hasFitCamera) return;

    final events = _pinnableEvents;
    if (events.isEmpty) return;
    // Mark up front so a second trigger while the animation runs is a no-op.
    _hasFitCamera = true;

    const padding = 60.0;
    // Extra room at the top so the topmost pin clears the header area.
    const topPadding = padding + 40;

    if (events.length == 1) {
      final only = events.single;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(only.latitude!, only.longitude!),
          13,
        ),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    var minLat = events.first.latitude!;
    var maxLat = events.first.latitude!;
    var minLng = events.first.longitude!;
    var maxLng = events.first.longitude!;
    for (final event in events.skip(1)) {
      minLat = math.min(minLat, event.latitude!);
      maxLat = math.max(maxLat, event.latitude!);
      minLng = math.min(minLng, event.longitude!);
      maxLng = math.max(maxLng, event.longitude!);
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: padding,
        top: topPadding,
        right: padding,
        bottom: padding,
      ),
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final textStyles = Theme.of(context).extension<CustomTextStyles>()!;
    _colors = colors;
    _textStyles = textStyles;
    _devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    // Subscribe to the event list so the pins refresh when it changes.
    final events = context.select<EventController, List<Event>>(
      (controller) => controller.events,
    );
    // Re-render when the event list changes, and when the theme changes — the
    // pin bitmaps bake in the theme's colours, so a palette switch has to
    // re-upload them to stay in step.
    final themeChanged = colors.accentColor != _accentBeforeBuild ||
        colors.cardColor != _cardBeforeBuild;
    if (!identical(events, _events) || themeChanged) {
      _events = events;
      _accentBeforeBuild = colors.accentColor;
      _cardBeforeBuild = colors.cardColor;
      // Sync after this build: MapLibre may still be loading its style, in
      // which case the style callback runs this itself. Fit once real events
      // land so the camera doesn't lock onto an empty map.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _syncPinsToMap();
        await _fitToPins();
      });
    }

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
