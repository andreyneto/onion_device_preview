import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/theme_list_item.dart';

/// Contextual pop-menu overlay: a `bg-pop-menu-{1..4}` panel (chosen by
/// action count), 320px wide with 60px rows.
///
/// Calibrated against the device (MainUI_008): MainUI anchors the panel
/// at the top-left corner (0,0), *covering the header*, with the first
/// row starting 2px in and the focused row drawing the same `bg-list-s`
/// bar clipped to the panel's width — and no scrim over the list behind
/// (unlike dialogs). The open-source `pop_menu.h` (used by apps, not
/// MainUI) anchors near the triggering item instead; the device behavior
/// wins here.
///
/// The Game Switcher's own pop menu is the same widget with its
/// open-source geometry passed in ([top] = the header's height,
/// [showScrim]/[preview] only while "Load" is selected — `pop_menu.h`
/// dims and previews only when handed a `transparent_bg`).
class PopMenuScreen extends StatefulWidget {
  const PopMenuScreen({
    super.key,
    required this.controller,
    required this.ctx,
    this.top = 0,
    this.showScrim = true,
    this.scrimColor = _deviceScrim,
    this.preview,
    this.onLeft,
    this.onRight,
  });

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  /// The dim measured on the device for MainUI's context menu
  /// (background 36,38,48 → 12,12,16 between MainUI_011 and MainUI_008).
  static const Color _deviceScrim = Color(0xAA000000);

  /// Where the panel's top edge sits (`y_pos`). The scrim starts here too
  /// (`bg_rect = {0, y_pos, w, h - y_pos}` — `pop_menu.h`).
  final double top;

  final bool showScrim;

  /// Defaults to the device-measured dim; the switcher passes the
  /// `0xBE000000` its own `transparent_bg` is filled with
  /// (`gameSwitcher.c:62-63`).
  final Color scrimColor;

  /// An image shown in the right-hand preview band (`preview_width` 320,
  /// scaled to fit and centered on y=240 — `list.h:186-216`).
  final ui.Image? preview;

  /// Left/right handlers for menus whose focused row has its own axis
  /// (the switcher's save-state slot).
  final void Function()? onLeft;
  final void Function()? onRight;

  @override
  State<PopMenuScreen> createState() => _PopMenuScreenState();
}

class _PopMenuScreenState extends State<PopMenuScreen> {
  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant PopMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The left/right handlers close over the *current* selection, so they
    // must be refreshed whenever the parent rebuilds with new ones.
    _bind();
  }

  void _bind() {
    // Keyed by screen kind — shadows the base screen's handlers while
    // open, without ever touching them (see bindScreenHandlers).
    widget.controller.bindScreenHandlers(
      OnionScreenKind.popMenu,
      onConfirm: _confirm,
      onCancel: widget.controller.goBack,
      onLeft: widget.onLeft,
      onRight: widget.onRight,
    );
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.popMenu);
    super.dispose();
  }

  List<String> get _actions => widget.controller.popMenuActions;

  int get _activeIndex =>
      _actions.isEmpty ? 0 : widget.controller.selectionFor(OnionScreenKind.popMenu).clamp(0, _actions.length - 1);

  void _confirm() => widget.controller.popMenuOnSelect?.call(_activeIndex);

  ThemeAsset _bgFor(int count) => switch (count.clamp(1, 4)) {
        1 => ThemeAsset.bgPopMenu1,
        2 => ThemeAsset.bgPopMenu2,
        3 => ThemeAsset.bgPopMenu3,
        _ => ThemeAsset.bgPopMenu4,
      };

  @override
  Widget build(BuildContext context) {
    final actions = _actions;
    widget.controller.setItemCount(OnionScreenKind.popMenu, actions.length);
    if (actions.isEmpty) return const SizedBox.shrink();

    final activeIndex = _activeIndex;
    final bg = widget.ctx.image(_bgFor(actions.length));
    final panelHeight = bg?.height.toDouble() ?? (actions.length * 60.0 + 10);

    return Stack(
      children: [
        // Scrim behind the panel, from the panel's own top edge down: the
        // device dims the underlying list to ~1/3 of its brightness. The
        // footer is re-drawn ON TOP of this by the chrome (with OK/CANCEL
        // hints), like the firmware re-renders it above the popup.
        if (widget.showScrim)
          Positioned(
            left: 0,
            top: widget.top,
            right: 0,
            bottom: 0,
            child: ColoredBox(color: widget.scrimColor),
          ),
        if (widget.preview != null)
          Positioned.fill(child: CustomPaint(painter: _PreviewPainter(widget.preview!))),
        Positioned(
          left: 0,
          top: widget.top,
          width: 320,
          height: panelHeight,
          child: Stack(
            children: [
              if (bg != null) RawImage(image: bg, filterQuality: FilterQuality.none),
              // First row band starts 2px into the panel (MainUI_008:
              // the focused bar spans y=2..61).
              Positioned(
                top: 2,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    for (var i = 0; i < actions.length; i++)
                      ThemeListItem(
                        width: 320,
                        selected: i == activeIndex,
                        selectedBackground: widget.ctx.image(ThemeAsset.bgListSmall),
                        label: actions[i],
                        listStyle: widget.ctx.config.list,
                        listFontFamily: widget.ctx.fontFamily(widget.ctx.config.list.font),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The active row's preview image, scaled to the 320px band on the right
/// and centered on y=240 (`theme_renderListCustom`, `list.h:186-216`,
/// with `preview_bg: false` and `preview_stretch: true`).
class _PreviewPainter extends CustomPainter {
  const _PreviewPainter(this.preview);

  final ui.Image preview;

  static const double _width = 320;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _width / preview.width;
    final height = preview.height * scale;
    canvas.drawImageRect(
      preview,
      Rect.fromLTWH(0, 0, preview.width.toDouble(), preview.height.toDouble()),
      Rect.fromLTWH(640 - _width, 240 - height / 2, _width, height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) => oldDelegate.preview != preview;
}
