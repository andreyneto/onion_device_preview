import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../core/theme_config.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/onion_canvas.dart';

/// Full-screen dialog overlay — mirrors `theme_renderDialog` /
/// `theme_renderDialogProgress` (`Onion/src/common/theme/render/
/// dialog.h`) closely: the 33.3%-black scrim, centered `pop-bg`, title
/// (`total.color`) at `center.y + 25`, message (`grid.color`) at
/// `center.y + 160`, and — when [OnionPreviewController.dialogShowHint]
/// is set — the A/B hint math worked backwards from the popup's
/// right edge exactly as `dialog.h` computes it.
///
/// One deliberate deviation: the firmware's message textbox only breaks
/// on literal `\n` in the string and shrinks its font if the result is
/// still too wide (`__get_font_size`); this instead soft-wraps at the
/// same 450px width using Flutter's own text layout, which handles an
/// arbitrary long one-line mock message better without needing to
/// author it with manual newlines.
class DialogScreen extends StatefulWidget {
  const DialogScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  @override
  State<DialogScreen> createState() => _DialogScreenState();
}

class _DialogScreenState extends State<DialogScreen> {
  Timer? _progressTimer;
  int _progressDots = 0;

  @override
  void initState() {
    super.initState();
    // Handlers are keyed by screen kind, so binding under `dialog` never
    // touches — and is automatically shadowed over — whatever the base
    // screen underneath has registered.
    widget.controller.bindScreenHandlers(
      OnionScreenKind.dialog,
      onConfirm: _confirm,
      onCancel: widget.controller.goBack,
    );

    if (widget.controller.dialogShowProgress) {
      _progressTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        setState(() => _progressDots = (_progressDots + 1) % 4);
      });
    }
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.dialog);
    _progressTimer?.cancel();
    super.dispose();
  }

  void _confirm() {
    final onConfirm = widget.controller.dialogOnConfirm;
    widget.controller.goBack();
    onConfirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _DialogPainter(
          config: widget.ctx.config,
          popBg: widget.ctx.image(ThemeAsset.popBg),
          buttonA: widget.ctx.image(ThemeAsset.buttonA),
          buttonB: widget.ctx.image(ThemeAsset.buttonB),
          progressDot: widget.ctx.image(ThemeAsset.progressDot),
          titleFontFamily: widget.ctx.fontFamily(widget.ctx.config.title.font),
          hintFontFamily: widget.ctx.fontFamily(widget.ctx.config.hint.font),
          title: widget.controller.dialogTitle,
          message: widget.controller.dialogMessage,
          showHint: widget.controller.dialogShowHint,
          showProgress: widget.controller.dialogShowProgress,
          progressDots: _progressDots,
        ),
      ),
    );
  }
}

class _DialogPainter extends CustomPainter {
  const _DialogPainter({
    required this.config,
    required this.popBg,
    required this.buttonA,
    required this.buttonB,
    required this.progressDot,
    required this.titleFontFamily,
    required this.hintFontFamily,
    required this.title,
    required this.message,
    required this.showHint,
    required this.showProgress,
    required this.progressDots,
  });

  final OnionThemeConfig config;
  final ui.Image? popBg;
  final ui.Image? buttonA;
  final ui.Image? buttonB;
  final ui.Image? progressDot;
  final String titleFontFamily;
  final String hintFontFamily;
  final String title;
  final String message;
  final bool showHint;
  final bool showProgress;
  final int progressDots;

  static const _dialogWidth = 450.0;

  /// `textbox.h:39` — `line_height = 1.2 * TTF_FontLineSkip(font)`.
  static const _lineHeightFactor = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x55000000));

    final popW = popBg?.width.toDouble() ?? 450;
    final popH = popBg?.height.toDouble() ?? 250;
    final centerRect = Rect.fromLTWH((size.width - popW) / 2, (size.height - popH) / 2, popW, popH);

    canvas.drawImageTopLeft(popBg, centerRect.topLeft);

    if (title.isNotEmpty) {
      // `dialog.h:45` renders the title with the TITLE font — i.e. the
      // theme's `title.font`/`title.size` — and takes only the *color*
      // from `total`. Using `total.size` here would pick up the fallback
      // chain total <- hint, which 15 real themes resolve to 0 (an
      // invisible title) and 145 more to a size the device never uses.
      final titleStyle = OnionFontStyle(font: config.title.font, size: config.title.size, color: config.total.color);
      final titlePainter = OnionCanvasOps.layoutOnionText(title, style: titleStyle, fontFamily: titleFontFamily);
      titlePainter.paint(
        canvas,
        Offset((size.width - titlePainter.width) / 2, centerRect.top + 25 - titlePainter.height / 2),
      );
    }

    if (message.isNotEmpty) {
      final messageStyle = OnionFontStyle(font: config.title.font, size: config.title.size, color: config.grid.color);
      final baseStyle = TextStyle(
        fontFamily: titleFontFamily,
        fontSize: messageStyle.size.toDouble(),
        color: messageStyle.color,
      );
      // `textbox.h:39` stacks the lines at 1.2x the font's own line skip,
      // which is what the device shows (36px pitch at Silky's 25px title
      // font); Flutter's default pitch is the bare line skip, 29px.
      // [MEAS-device] MainUI/GameSwitcher remove-from-history capture.
      final singleLine = TextPainter(
        text: TextSpan(text: 'X', style: baseStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final lineSkip = singleLine.preferredLineHeight;
      final messagePainter = TextPainter(
        text: TextSpan(
          text: message,
          style: baseStyle.copyWith(height: _lineHeightFactor * lineSkip / messageStyle.size),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: _dialogWidth);
      messagePainter.paint(
        canvas,
        Offset((size.width - messagePainter.width) / 2, centerRect.top + 160 - messagePainter.height / 2),
      );
    }

    if (showHint) {
      _paintHints(canvas, centerRect);
    } else if (showProgress) {
      _paintProgress(canvas, size);
    }
  }

  void _paintHints(Canvas canvas, Rect centerRect) {
    if (buttonA == null) return;
    final labelOk = OnionCanvasOps.layoutOnionText('OK', style: config.hint, fontFamily: hintFontFamily);
    final labelCancel = OnionCanvasOps.layoutOnionText('CANCEL', style: config.hint, fontFamily: hintFontFamily);
    final btnBWidth = buttonB?.width.toDouble() ?? 0;

    var x = centerRect.right - 30;
    final y = centerRect.bottom - 60;

    x -= buttonA!.width + 5;
    x -= labelOk.width + 30;
    x -= btnBWidth + 5;
    x -= labelCancel.width + 30;

    canvas.drawImageTopLeft(buttonA, Offset(x, y - buttonA!.height / 2));
    x += buttonA!.width + 5;
    labelOk.paint(canvas, Offset(x, y - labelOk.height / 2));
    x += labelOk.width + 30;

    if (buttonB != null) {
      canvas.drawImageTopLeft(buttonB, Offset(x, y - buttonB!.height / 2));
      x += buttonB!.width + 5;
    }
    labelCancel.paint(canvas, Offset(x, y - labelCancel.height / 2));
  }

  void _paintProgress(Canvas canvas, Size size) {
    if (progressDot == null) return;
    var x = (size.width - progressDot!.width) / 2 - 32;
    const y = 225.0;
    for (var i = 0; i < 3; i++) {
      if (progressDots >= i + 1) {
        canvas.drawImageTopLeft(progressDot, Offset(x, y - progressDot!.height / 2));
      }
      x += 32;
    }
  }

  @override
  bool shouldRepaint(covariant _DialogPainter oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.message != message ||
        oldDelegate.showHint != showHint ||
        oldDelegate.showProgress != showProgress ||
        oldDelegate.progressDots != progressDots;
  }
}
