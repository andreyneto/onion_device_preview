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
class PopMenuScreen extends StatefulWidget {
  const PopMenuScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  @override
  State<PopMenuScreen> createState() => _PopMenuScreenState();
}

class _PopMenuScreenState extends State<PopMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Keyed by screen kind — shadows the base screen's handlers while
    // open, without ever touching them (see bindScreenHandlers).
    widget.controller.bindScreenHandlers(
      OnionScreenKind.popMenu,
      onConfirm: _confirm,
      onCancel: widget.controller.goBack,
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
        // Scrim over the whole screen behind the panel: the device dims
        // the underlying list to ~1/3 of its brightness (MainUI_008 vs
        // MainUI_011: background 36,38,48 → 12,12,16). The footer is
        // re-drawn ON TOP of this by the chrome (with OK/CANCEL hints),
        // like the firmware re-renders it above the popup.
        const Positioned.fill(child: ColoredBox(color: Color(0xAA000000))),
        Positioned(
          left: 0,
          top: 0,
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
