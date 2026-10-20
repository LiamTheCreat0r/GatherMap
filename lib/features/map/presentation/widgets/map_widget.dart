import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../core/theme/custom_text_styles.dart';
import '../../../../core/widgets/loading_dots.dart';
import '../../../../services/location_service.dart';
import '../../../events/domain/event.dart';
import '../../../events/presentation/event_controller.dart';
import 'event_pin.dart';

/// GeoJSON source holding every pinned event as a point feature.
const String _eventsSourceId = 'event-pins';

/// Symbol layer drawing those points with the rendered pin images.
const String _eventsLayerId = 'event-pins-layer';

/// GeoJSON source holding the device's last known position, once located.
const String _userLocationSourceId = 'user-location';

/// Circle layer drawing that position as an accent-coloured dot.
const String _userLocationLayerId = 'user-location-layer';

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
///
/// A floating "locate me" button sits over the map. Tapping it asks for the
/// device's position through [LocationService] — which raises the platform's
/// permission prompt — then centres the camera on the fix and marks it with an
/// accent-coloured dot. Denials and disabled services surface as a snack bar
/// with a shortcut to the relevant settings.
class Map extends StatefulWidget {
  const Map({
    super.key,
    this.locationService = const LocationService(),
    this.selectedEvent,
    this.onSelectedEventChanged,
  });

  /// Resolves the device's position (with permission) for the locate button.
  /// Injectable so tests can supply a fake provider.
  final LocationService locationService;

  /// Event whose detail sheet is open, or `null` when no sheet is shown.
  ///
  /// The sheet itself lives one level up in `MapPage`, above the header and
  /// floating button; this widget only reports pin selections.
  final Event? selectedEvent;

  /// Reports a pin tap (`event`) or a map-background tap (`null`).
  final ValueChanged<Event?>? onSelectedEventChanged;

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

  /// Latest device position, drawn as an accent dot. Null until a locate
  /// succeeds.
  LatLng? _userLocation;

  /// True while a locate is in flight; the button shows a spinner.
  bool _isLocating = false;

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

  @override
  void dispose() {
    _controller?.onFeatureTapped.remove(_onFeatureTapped);
    super.dispose();
  }

  /// Wires the controller up as soon as the platform view exists.
  ///
  /// The listener is registered here rather than in [_onStyleLoaded]: a style
  /// reload does not recreate the controller, and registering per style load
  /// would accumulate duplicate callbacks.
  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onFeatureTapped.add(_onFeatureTapped);
  }

  /// Opens the bottom detail sheet for a tapped event pin.
  ///
  /// The tapped feature id is not guaranteed to be the event id across
  /// platforms, so the feature's own `eventId` property is read back with
  /// [MapLibreMapController.queryRenderedFeatures]; the callback id is only a
  /// fallback when that query fails.
  Future<void> _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) async {
    if (layerId != _eventsLayerId) return;
    final controller = _controller;
    if (controller == null || !mounted) return;

    String? eventId;
    try {
      final features = await controller.queryRenderedFeatures(point, const [
        _eventsLayerId,
      ], null);
      if (features.isNotEmpty) {
        final dynamic feature = features.first;
        final dynamic properties = feature['properties'];
        eventId = properties?['eventId']?.toString();
      }
    } on Object {
      // Fall back to the raw feature id below.
    }

    eventId ??= id;
    if (!mounted) return;

    Event? tapped;
    for (final event in _events) {
      if (event.id == eventId) {
        tapped = event;
        break;
      }
    }
    if (tapped == null) return;

    widget.onSelectedEventChanged?.call(tapped);
  }

  /// Closes the detail sheet when the map background is tapped.
  void _dismissSelectedEvent(Point<double> point, LatLng coordinates) {
    if (widget.selectedEvent == null) return;
    widget.onSelectedEventChanged?.call(null);
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
    await controller.addGeoJsonSource(
      _userLocationSourceId,
      _emptyFeatureCollection,
    );
    await controller.addCircleLayer(
      _userLocationSourceId,
      _userLocationLayerId,
      CircleLayerProperties(
        // A dot the size of a fingertip, ringed in white so it stays legible
        // over any basemap.
        circleRadius: 7,
        circleColor: _hexColor(_colors?.accentColor ?? const Color(0xFFF26419)),
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
        circleOpacity: 0.95,
      ),
    );
    if (!mounted || controller != _controller) return;
    await _syncPinsToMap();
    await _fitToPins();
    await _syncUserLocationToMap();
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
          'id': event.id,
          'properties': {
            'icon': iconId,
            'name': event.name,
            'eventId': event.id,
          },
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
        CameraUpdate.newLatLngZoom(LatLng(only.latitude!, only.longitude!), 13),
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

  /// Pushes the stored device fix into its GeoJSON source, if the style is
  /// ready. Safe to call before a fix exists or before the style loads.
  Future<void> _syncUserLocationToMap() async {
    final controller = _controller;
    final location = _userLocation;
    if (controller == null || location == null || !_isStyleLoaded) return;

    await controller.setGeoJsonSource(_userLocationSourceId, {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [location.longitude, location.latitude],
          },
        },
      ],
    });
  }

  /// Asks for the device's position — prompting for permission — then centres
  /// the camera on the fix and marks it.
  Future<void> _locateUser() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    final result = await widget.locationService.locate();
    if (!mounted) return;
    setState(() => _isLocating = false);

    final location = result.location;
    if (location == null) {
      _showLocationFailure(result.failure!);
      return;
    }

    final target = LatLng(location.latitude, location.longitude);
    setState(() => _userLocation = target);
    await _syncUserLocationToMap();

    final controller = _controller;
    if (controller == null || !_isStyleLoaded) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, 15),
      duration: const Duration(milliseconds: 600),
    );
  }

  /// Explains why a locate failed, with a shortcut to the settings that can
  /// unblock it.
  void _showLocationFailure(LocationFailure failure) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_locationFailureMessage(failure)),
        action: switch (failure) {
          LocationFailure.serviceDisabled => SnackBarAction(
            label: 'Paramètres',
            onPressed: () => widget.locationService.openLocationSettings(),
          ),
          LocationFailure.permissionDeniedForever => SnackBarAction(
            label: 'Paramètres',
            onPressed: () => widget.locationService.openAppSettings(),
          ),
          LocationFailure.permissionDenied ||
          LocationFailure.unavailable => null,
        },
      ),
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
    final themeChanged =
        colors.accentColor != _accentBeforeBuild ||
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

    // A refresh can drop the event whose sheet is open; close it rather than
    // leaving stale details on screen.
    final selected = widget.selectedEvent;
    if (selected != null && !events.any((event) => event.id == selected.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final current = widget.selectedEvent;
        if (current != null &&
            !_events.any((event) => event.id == current.id)) {
          widget.onSelectedEventChanged?.call(null);
        }
      });
    }

    return Stack(
      children: [
        MapLibreMap(
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          onMapClick: _dismissSelectedEvent,
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
        // Locate control. Sits above the loading overlay so it stays tappable
        // from the first frame.
        Positioned(
          top: 16,
          right: 16,
          child: _LocateButton(
            isLoading: _isLocating,
            colors: colors,
            onPressed: _locateUser,
          ),
        ),
      ],
    );
  }
}

/// `#RRGGBB` for a MapLibre style colour, dropping the alpha channel.
String _hexColor(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// User-facing explanation for a failed locate.
String _locationFailureMessage(LocationFailure failure) => switch (failure) {
  LocationFailure.serviceDisabled =>
    'Activez la localisation de votre appareil pour vous situer sur la carte.',
  LocationFailure.permissionDenied => 'Autorisation de localisation refusée.',
  LocationFailure.permissionDeniedForever =>
    'Autorisation refusée. Activez-la dans les paramètres.',
  LocationFailure.unavailable =>
    'Impossible de récupérer votre position pour le moment.',
};

/// Circular, tappable "locate me" control floating over the map.
///
/// Shows a spinner in place of the crosshair while a fix is in flight, and is
/// inert in that state so a second tap cannot start a parallel lookup.
class _LocateButton extends StatelessWidget {
  const _LocateButton({
    required this.isLoading,
    required this.colors,
    required this.onPressed,
  });

  final bool isLoading;
  final CustomColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ma position',
      child: Material(
        color: colors.cardColor,
        elevation: 3,
        shape: CircleBorder(
          side: BorderSide(color: colors.borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accentColor,
                    ),
                  )
                : Icon(Icons.my_location, size: 22, color: colors.accentColor),
          ),
        ),
      ),
    );
  }
}
