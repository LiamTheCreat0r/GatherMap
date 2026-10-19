import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../core/theme/custom_text_styles.dart';

// --- Pin geometry (logical pixels), shared by every rendering path. ---
const double _pillHPad = 12;
const double _pillVPad = 7;
const double _pillRadius = 16;
const double _gap = 4; // pill → emoji bubble
const double _bubble = 32;
const double _bubbleBorder = 2;
const double _emojiSize = 16;
const double _triangleW = 14;
const double _triangleH = 7;
const double _dot = 10;
const double _dotBorder = 2;

// Transparent margin so the pill/bubble shadows aren't clipped by the bitmap
// edge. Kept at zero along the bottom so the anchor dot's base stays exactly
// at the image bottom — that edge is what MapLibre pins to the coordinate.
const double _bleedX = 10;
const double _bleedTop = 10;
const double _bleedBottom = 0;

/// One event marker, drawn as a pinpoint.
///
/// ```text
///   ┌───────────────┐
///   │ Rooftop Party │  pill — orange background, white label
///   └───────┬───────┘
///         ( 🎉 )      emoji bubble — theme disc, orange ring
///            ▼        triangular pointer — orange
///            •        geographic anchor — orange dot, white ring
/// ```
///
/// The pin's design lives entirely in [paintEventPin] / [measureEventPin], so
/// the exact same drawing backs both this widget (used in previews and tests)
/// and the PNG the map uploads as a style image. Rendering the pin to a bitmap
/// lets MapLibre place it natively as a symbol layer, which is what keeps it
/// glued to its coordinate under pan and zoom with no Flutter-side projection.
class EventPin extends StatelessWidget {
  const EventPin({
    super.key,
    required this.name,
    required this.emoji,
    this.maxLabelWidth = 148,
  });

  /// Event name shown in the pill.
  final String name;

  /// Emoji shown in the bubble, e.g. `🎉`.
  final String emoji;

  /// Pill label wraps at this width before ellipsising, so long names don't
  /// stretch the pin across the map.
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final textStyles = Theme.of(context).extension<CustomTextStyles>()!;
    final size = measureEventPin(
      name: name,
      colors: colors,
      textStyles: textStyles,
      maxLabelWidth: maxLabelWidth,
    );
    return CustomPaint(
      size: size,
      painter: EventPinPainter(
        name: name,
        emoji: emoji,
        colors: colors,
        textStyles: textStyles,
        maxLabelWidth: maxLabelWidth,
      ),
    );
  }
}

/// Lays out the pill label and derives the pin's content dimensions.
///
/// The label is returned still alive so [paintEventPin] can paint it; callers
/// are responsible for disposing it.
({TextPainter label, double pillW, double pillH, double contentW, double contentH})
    _layoutPin(
      String name,
      CustomColors colors,
      CustomTextStyles textStyles,
      double maxLabelWidth,
    ) {
  final label = TextPainter(
    text: TextSpan(
      text: name,
      style: textStyles.labelStyle.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
    maxLines: 1,
    ellipsis: '…',
    textAlign: TextAlign.center,
    // No ambient Directionality on the bitmap path, and the label is centred
    // anyway, so the pin fixes its direction.
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: math.max(maxLabelWidth - _pillHPad * 2, 0));

  final pillW = label.width + _pillHPad * 2;
  final pillH = label.height + _pillVPad * 2;
  // Widest of pill, bubble, triangle and dot — all centre-aligned like the
  // widget's Column.
  final contentW = math.max(pillW, math.max(_bubble, math.max(_triangleW, _dot)));
  final contentH = pillH + _gap + _bubble + _triangleH + _dot;
  return (label: label, pillW: pillW, pillH: pillH, contentW: contentW, contentH: contentH);
}

/// Logical size of the rendered pin, including the shadow bleed margin.
Size measureEventPin({
  required String name,
  required CustomColors colors,
  required CustomTextStyles textStyles,
  double maxLabelWidth = 148,
}) {
  final laid = _layoutPin(name, colors, textStyles, maxLabelWidth);
  laid.label.dispose();
  return Size(
    laid.contentW + _bleedX * 2,
    laid.contentH + _bleedTop + _bleedBottom,
  );
}

/// Paints the pin with its top-left at the canvas origin.
///
/// The drawn extent is [measureEventPin]; the anchor dot's base sits on the
/// bottom edge, horizontally centred — the point MapLibre pins to the
/// coordinate with `iconAnchor: 'bottom'`.
void paintEventPin(
  Canvas canvas, {
  required String name,
  required String emoji,
  required CustomColors colors,
  required CustomTextStyles textStyles,
  double maxLabelWidth = 148,
}) {
  final accent = colors.accentColor;
  final laid = _layoutPin(name, colors, textStyles, maxLabelWidth);
  final cx = laid.contentW / 2;

  canvas.save();
  canvas.translate(_bleedX, _bleedTop);

  // Name pill, with its drop shadow painted behind it.
  final pillLeft = (laid.contentW - laid.pillW) / 2;
  final pill = RRect.fromRectAndRadius(
    Rect.fromLTWH(pillLeft, 0, laid.pillW, laid.pillH),
    const Radius.circular(_pillRadius),
  );
  canvas.drawRRect(
    pill.shift(const Offset(0, 2)),
    Paint()
      ..color = Colors.black26
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3),
  );
  canvas.drawRRect(pill, Paint()..color = accent);
  laid.label.paint(canvas, Offset(pillLeft + _pillHPad, _pillVPad));
  laid.label.dispose();

  // Emoji bubble: theme disc ringed in the accent colour, shadow behind.
  final bubbleCenter = Offset(cx, laid.pillH + _gap + _bubble / 2);
  canvas.drawCircle(
    bubbleCenter + const Offset(0, 1),
    _bubble / 2,
    Paint()
      ..color = Colors.black26
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
  );
  canvas.drawCircle(bubbleCenter, _bubble / 2, Paint()..color = colors.cardColor);
  canvas.drawCircle(
    bubbleCenter,
    _bubble / 2 - _bubbleBorder / 2,
    Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = _bubbleBorder,
  );
  final emojiLayout = TextPainter(
    text: TextSpan(text: emoji, style: const TextStyle(fontSize: _emojiSize)),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  emojiLayout.paint(
    canvas,
    Offset(bubbleCenter.dx - emojiLayout.width / 2, bubbleCenter.dy - emojiLayout.height / 2),
  );
  emojiLayout.dispose();

  // Triangular pointer bridging the bubble down to the anchor dot.
  final triTop = laid.pillH + _gap + _bubble;
  final triLeft = cx - _triangleW / 2;
  final triangle = Path()
    ..moveTo(triLeft, triTop)
    ..lineTo(triLeft + _triangleW, triTop)
    ..lineTo(cx, triTop + _triangleH)
    ..close();
  canvas.drawPath(triangle, Paint()..color = accent);

  // Geographic anchor. The white ring keeps the orange dot visible against the
  // cream map background; its base defines the pin's bottom edge.
  final dotCenter = Offset(cx, triTop + _triangleH + _dot / 2);
  canvas.drawCircle(dotCenter, _dot / 2, Paint()..color = accent);
  canvas.drawCircle(
    dotCenter,
    _dot / 2 - _dotBorder / 2,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = _dotBorder,
  );

  canvas.restore();
}

/// Renders the pin to a PNG sized for [devicePixelRatio].
///
/// MapLibre registers these images with the device pixel ratio as their
/// `pixelRatio` (iOS passes `UIScreen.main.scale` when decoding), so the bitmap
/// must be painted at `logical × devicePixelRatio` to come out at the intended
/// logical size — and at full device resolution rather than looking soft.
Future<Uint8List> renderEventPinPng({
  required String name,
  required String emoji,
  required CustomColors colors,
  required CustomTextStyles textStyles,
  required double devicePixelRatio,
  double maxLabelWidth = 148,
}) async {
  final logical = measureEventPin(
    name: name,
    colors: colors,
    textStyles: textStyles,
    maxLabelWidth: maxLabelWidth,
  );
  final width = (logical.width * devicePixelRatio).ceil();
  final height = (logical.height * devicePixelRatio).ceil();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(devicePixelRatio);
  paintEventPin(
    canvas,
    name: name,
    emoji: emoji,
    colors: colors,
    textStyles: textStyles,
    maxLabelWidth: maxLabelWidth,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return byteData!.buffer.asUint8List();
}

/// [CustomPainter] that defers to [paintEventPin], for widget use.
class EventPinPainter extends CustomPainter {
  const EventPinPainter({
    required this.name,
    required this.emoji,
    required this.colors,
    required this.textStyles,
    this.maxLabelWidth = 148,
  });

  final String name;
  final String emoji;
  final CustomColors colors;
  final CustomTextStyles textStyles;
  final double maxLabelWidth;

  @override
  void paint(Canvas canvas, Size size) {
    paintEventPin(
      canvas,
      name: name,
      emoji: emoji,
      colors: colors,
      textStyles: textStyles,
      maxLabelWidth: maxLabelWidth,
    );
  }

  @override
  bool shouldRepaint(EventPinPainter oldDelegate) =>
      oldDelegate.name != name ||
      oldDelegate.emoji != emoji ||
      oldDelegate.colors != colors ||
      oldDelegate.textStyles != textStyles ||
      oldDelegate.maxLabelWidth != maxLabelWidth;
}
