import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../core/theme_config.dart';

/// SDL-blit-style drawing helpers on top of [Canvas], so painters read
/// like the firmware's own `SDL_BlitSurface` calls: a rect's `{x, y}` is
/// always its top-left corner, and "centered at (cx, cy)" always means
/// `{cx - w/2, cy - h/2}` (the idiom `Onion/src/common/theme/render/*.h`
/// uses throughout).
extension OnionCanvasOps on Canvas {
  /// Mirrors `SDL_BlitSurface(image, NULL, screen, &rect)` with
  /// `rect = {topLeft.x, topLeft.y}`.
  void drawImageTopLeft(ui.Image? image, Offset topLeft) {
    if (image == null) return;
    drawImage(image, topLeft, Paint()..filterQuality = FilterQuality.none);
  }

  /// Mirrors the firmware's `{cx - w/2, cy - h/2}` centering idiom (e.g.
  /// the battery icon in `render/header.h:19`).
  void drawImageCentered(ui.Image? image, Offset center) {
    if (image == null) return;
    drawImageTopLeft(image, Offset(center.dx - image.width / 2, center.dy - image.height / 2));
  }

  /// Mirrors `SDL_BlitSurface(image, &srcRect, screen, &dstRect)`: crops
  /// [image] to [from] (clamped to the image's own bounds) and draws that
  /// region at [to]. Used to sample just the header/footer strip of the
  /// full-screen `background` image (`render/header.h:12`,
  /// `render/footer.h:67`), where [from] is that strip's position in the
  /// full 640x480 background but [to] is local to whatever's actually
  /// being painted (e.g. the footer widget's own 640x60 canvas, which
  /// starts its own coordinates at 0 regardless of where it sits
  /// on screen).
  void drawImageRegion(ui.Image? image, {required Rect from, required Rect to}) {
    if (image == null) return;
    final srcWidth = from.width < image.width ? from.width : image.width.toDouble();
    final srcHeight = from.height < image.height ? from.height : image.height.toDouble();
    drawImageRect(
      image,
      Rect.fromLTWH(from.left, from.top, srcWidth, srcHeight),
      to,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  /// Lays out and paints [text] at [topLeft], returning the [TextPainter]
  /// so callers can read its size for further positioning — mirroring how
  /// the firmware reads `surface->w/h` right after
  /// `TTF_RenderUTF8_Blended`. Returns `null` (nothing painted) for empty
  /// text, matching `TTF_RenderUTF8_Blended`'s behavior of never being
  /// called with a blank string in practice.
  TextPainter? paintOnionText(
    String text, {
    required OnionFontStyle style,
    required String fontFamily,
    required Offset topLeft,
    bool bold = false,
    double opacity = 1,
  }) {
    if (text.isEmpty) return null;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: style.size.toDouble(),
          color: style.color.withAlpha((opacity.clamp(0, 1) * 0xFF).round()),
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(this, topLeft);
    return painter;
  }

  /// Lays out [text] without painting it, for callers that need its size
  /// up front to compute other elements' positions (e.g. the battery
  /// percentage composite, or a list item's toggle-aware label crop).
  static TextPainter layoutOnionText(
    String text, {
    required OnionFontStyle style,
    required String fontFamily,
    bool bold = false,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: style.size.toDouble(),
          color: style.color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
