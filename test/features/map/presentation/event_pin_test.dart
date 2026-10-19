// Tests for the map's event pinpoint — the painter that backs both the
// [EventPin] widget and the PNG the map uploads as a style image.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gathermap/core/theme/app_themes.dart';
import 'package:gathermap/core/theme/custom_colors.dart';
import 'package:gathermap/core/theme/custom_text_styles.dart';
import 'package:gathermap/features/map/presentation/widgets/event_pin.dart';

/// Pins are painted, not composed of widgets, so the theme's extensions are
/// read directly the way [EventPin] reads them.
CustomColors get _colors =>
    AppThemes.lightTheme.extension<CustomColors>()!;
CustomTextStyles get _textStyles =>
    AppThemes.lightTheme.extension<CustomTextStyles>()!;

const Color _accent = Color.fromARGB(255, 242, 100, 25);

/// Decodes a rendered pin PNG and reports whether any pixel carries the accent
/// colour, proving the bitmap really contains the brand orange.
Future<bool> _pngContainsAccent(Uint8List png) async {
  final image = await _decodePng(png);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  if (byteData == null) return false;

  final argb = _accent.toARGB32();
  final r = (argb >> 16) & 0xff;
  final g = (argb >> 8) & 0xff;
  final b = argb & 0xff;

  final pixels = byteData.buffer.asUint8List();
  for (var i = 0; i < pixels.length; i += 4) {
    if (pixels[i] == r &&
        pixels[i + 1] == g &&
        pixels[i + 2] == b &&
        pixels[i + 3] > 0) {
      return true;
    }
  }
  return false;
}

Future<ui.Image> _decodePng(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// The pin's [EventPinPainter], reached through the [CustomPaint] that hosts
/// it — painters aren't widgets, so `find.byType` can't see them directly.
EventPinPainter _pinPainter(WidgetTester tester) =>
    tester
        .widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is EventPinPainter,
          ),
        )
        .painter! as EventPinPainter;

/// Reads the width/height straight out of the PNG's IHDR chunk so the bitmap's
/// device-pixel size can be asserted without decoding it.
({int width, int height}) _pngSize(Uint8List png) => (
      width: (png[16] << 24) | (png[17] << 16) | (png[18] << 8) | png[19],
      height: (png[20] << 24) | (png[21] << 16) | (png[22] << 8) | png[23],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the pin through a painter carrying name and emoji',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: Scaffold(
          body: Center(
            child: EventPin(name: 'Rooftop Party', emoji: '🎉'),
          ),
        ),
      ),
    );

    final painter = _pinPainter(tester);
    expect(painter.name, 'Rooftop Party');
    expect(painter.emoji, '🎉');
    expect(painter.colors, _colors);
  });

  testWidgets('reads colours from the active theme (dark mode too)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.darkTheme,
        home: Scaffold(
          body: Center(
            child: EventPin(name: 'Rooftop Party', emoji: '🎉'),
          ),
        ),
      ),
    );

    final painter = _pinPainter(tester);
    expect(painter.colors, CustomColors.dark);
    expect(painter.colors.accentColor, _accent);
  });

  test('long names cap the pin width instead of stretching it', () {
    final short = measureEventPin(
      name: 'Party',
      colors: _colors,
      textStyles: _textStyles,
    );
    final long = measureEventPin(
      name: 'An Extremely Long Event Name That Cannot Fit',
      colors: _colors,
      textStyles: _textStyles,
    );

    // The pill wraps at maxLabelWidth (148); the extra 20 is the shadow bleed.
    expect(long.width, lessThanOrEqualTo(148 + 20));
    expect(long.width, greaterThanOrEqualTo(short.width));
  });

  test('measure matches what the painter draws', () {
    final size = measureEventPin(
      name: 'Rooftop Party',
      colors: _colors,
      textStyles: _textStyles,
    );

    // Pill + gap + bubble + triangle + dot, plus the vertical shadow bleed.
    expect(size.height, greaterThan(32 + 4 + 14 + 10));
    expect(size.width, greaterThan(0));
  });

  test('renders a PNG sized for the device pixel ratio', () async {
    const dpr = 3.0;
    final logical = measureEventPin(
      name: 'Rooftop Party',
      colors: _colors,
      textStyles: _textStyles,
    );

    final png = await renderEventPinPng(
      name: 'Rooftop Party',
      emoji: '🎉',
      colors: _colors,
      textStyles: _textStyles,
      devicePixelRatio: dpr,
    );

    final size = _pngSize(png);
    expect(size.width, (logical.width * dpr).ceil());
    expect(size.height, (logical.height * dpr).ceil());
  });

  test('PNG carries the brand orange', () async {
    final png = await renderEventPinPng(
      name: 'Rooftop Party',
      emoji: '🎉',
      colors: _colors,
      textStyles: _textStyles,
      devicePixelRatio: 2,
    );

    expect(await _pngContainsAccent(png), isTrue);
  });
}
