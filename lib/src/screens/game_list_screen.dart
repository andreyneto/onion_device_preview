import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../core/mock_data.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/theme_list_item.dart';

/// The rom list, calibrated against real-device screenshots
/// (MainUI_009/010/011 — see `docs/spec-1a1.md` §5):
///
///   rows    full-width (640) 60px rows from y=60, text at x=20, no
///           dividers; the focused row blits `bg-list-s`; long titles
///           hard-clip at the edge (no ellipsis)
///   cursor  moves within the visible window and only scrolls the list
///           when it crosses the top/bottom edge (NOT centered)
///   star    `ic-favorite-mark` sits against the right edge of a
///           favorite's row (x=586 for the 34px mark), not as a
///           leading icon
///   preview the right-hand preview panel (`preview-bg` + thumbnail,
///           `list.h` coordinates) only appears when the selected rom
///           actually has cover art — the mock has none, and the device
///           renders full-width rows without it (MainUI_009)
class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  static const _kVisibleRows = 6;

  /// First visible row. Device scroll model (MainUI_010): the cursor
  /// walks the visible rows and the window only shifts when it would
  /// leave them — it is NOT kept centered.
  int _windowStart = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.bindScreenHandlers(OnionScreenKind.gameList, onConfirm: _launch, onSelect: _openContextMenu);
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.gameList);
    super.dispose();
  }

  List<OnionMockRom> get _roms => widget.controller.gameRoms;

  int get _activeIndex =>
      _roms.isEmpty ? 0 : widget.controller.selectionFor(OnionScreenKind.gameList).clamp(0, _roms.length - 1);

  void _launch() {
    if (_roms.isEmpty) return;
    widget.controller.showDialog(title: _roms[_activeIndex].name, message: 'Launched (mock).');
  }

  void _openContextMenu() {
    if (_roms.isEmpty) return;
    final rom = _roms[_activeIndex];
    widget.controller.showPopMenu(
      const ['Toggle Favorite', 'Game Info', 'Cancel'],
      onSelect: (i) {
        widget.controller.goBack();
        if (i == 0) {
          widget.controller.showDialog(title: rom.name, message: 'Marked as favorite (mock).');
        } else if (i == 1) {
          widget.controller.showDialog(title: rom.name, message: 'No further info available in this preview.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roms = _roms;
    widget.controller.setItemCount(OnionScreenKind.gameList, roms.length);

    if (roms.isEmpty) {
      return Center(
        child: RawImage(image: widget.ctx.image(ThemeAsset.emptyBg), filterQuality: FilterQuality.none),
      );
    }

    final activeIndex = _activeIndex;
    final maxStart = (roms.length - _kVisibleRows).clamp(0, roms.length);
    if (activeIndex < _windowStart) _windowStart = activeIndex;
    if (activeIndex > _windowStart + _kVisibleRows - 1) _windowStart = activeIndex - _kVisibleRows + 1;
    _windowStart = _windowStart.clamp(0, maxStart);
    final lastIndex = (_windowStart + _kVisibleRows).clamp(0, roms.length);

    // Rows start 2px into the content band (device rows sit at screen
    // y=62, 122, ... — the 6th is clipped 2px by the footer).
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        for (var i = _windowStart; i < lastIndex; i++)
          Positioned(
            left: 0,
            top: 2 + 60.0 * (i - _windowStart),
            child: ThemeListItem(
              width: 640,
              selected: i == activeIndex,
              selectedBackground: widget.ctx.image(ThemeAsset.bgListSmall),
              trailingMark: roms[i].isFavorite ? widget.ctx.image(ThemeAsset.favoriteMark) : null,
              label: roms[i].name,
              listStyle: widget.ctx.config.list,
              listFontFamily: widget.ctx.fontFamily(widget.ctx.config.list.font),
            ),
          ),
      ],
    );
  }
}
