import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../core/mock_data.dart';
import '../core/theme_config.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/onion_canvas.dart';

/// The "Games" tab's landing screen: a paged 2x4 grid of game *systems*
/// (a fixed "Search" cell first, then the consoles), calibrated
/// coordinate-by-coordinate against real-device screenshots
/// (MainUI_004/005 — see `docs/spec-1a1.md` §6):
///
///   cards  bg-game-item-{n,f} 154x170 at x = 10 + 155·col,
///          y = 66 + 170·row (screen coords) — same 4-column pitch as
///          the main menu; the focused card is the `-f` asset, normal
///          cells blit `-n` (near-invisible in most skins)
///   icons  console icons 120x130 (SD Icons pack / theme `icons/` dir),
///          centered on the card's x, top at card_y + 19
///   labels centered on card x, line center at card_y + 144.5, font
///          grid.font @ grid3x4, colors grid.color/selectedcolor
///   pages  8 cells per page, "page/pages" counter in the footer
class GameSystemsScreen extends StatefulWidget {
  const GameSystemsScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  static const int cellsPerPage = 8;
  static const int columns = 4;

  /// Total selectable cells (Search + systems) — used by the footer's
  /// page counter as well.
  static int get cellCount => OnionMockData.gameSystems.length + 1;

  static int get pageCount => (cellCount + cellsPerPage - 1) ~/ cellsPerPage;

  @override
  State<GameSystemsScreen> createState() => _GameSystemsScreenState();
}

class _GameSystemsScreenState extends State<GameSystemsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.bindScreenHandlers(OnionScreenKind.gameSystems, onConfirm: _activate);
    widget.controller.setGridColumns(OnionScreenKind.gameSystems, GameSystemsScreen.columns);
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.gameSystems);
    widget.controller.setGridColumns(OnionScreenKind.gameSystems, null);
    super.dispose();
  }

  int get _activeIndex =>
      widget.controller.horizontalFor(OnionScreenKind.gameSystems).clamp(0, GameSystemsScreen.cellCount - 1);

  void _activate() {
    final index = _activeIndex;
    if (index == 0) {
      widget.controller.showDialog(
        title: 'Search',
        message: 'Not implemented in this preview (see the backlog).',
      );
      return;
    }
    final system = OnionMockData.gameSystems[index - 1];
    widget.controller.openGameList(system.roms, system.name);
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.setColumnCount(OnionScreenKind.gameSystems, GameSystemsScreen.cellCount);

    final labels = <String>['Search', for (final s in OnionMockData.gameSystems) s.name];
    final iconNames = <String>['search', for (final s in OnionMockData.gameSystems) s.iconName];
    final selected = _activeIndex;

    return CustomPaint(
      size: const Size(640, 360),
      painter: _GameSystemsPainter(
        labels: labels,
        // Icons come from the icon pack, not the skin, and the focused
        // cell gets the pack's `sel/` variant when it ships one (the
        // device's `iconsel`) — see IconPackResolver.
        icons: [
          for (var i = 0; i < iconNames.length; i++) widget.ctx.packIcon(iconNames[i], selected: i == selected),
        ],
        selected: selected,
        cardNormal: widget.ctx.image(ThemeAsset.bgGameItemNormal),
        cardFocused: widget.ctx.image(ThemeAsset.bgGameItemFocused),
        fontFamily: widget.ctx.fontFamily(widget.ctx.config.grid.font),
        fontSize: widget.ctx.config.grid.grid3x4,
        color: widget.ctx.config.grid.color,
        selectedColor: widget.ctx.config.grid.selectedColor,
      ),
    );
  }
}

class _GameSystemsPainter extends CustomPainter {
  const _GameSystemsPainter({
    required this.labels,
    required this.icons,
    required this.selected,
    required this.cardNormal,
    required this.cardFocused,
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    required this.selectedColor,
  });

  final List<String> labels;
  final List<ui.Image?> icons;
  final int selected;
  final ui.Image? cardNormal;
  final ui.Image? cardFocused;
  final String fontFamily;
  final int fontSize;
  final Color color;
  final Color selectedColor;

  // Screen-space geometry ([MEAS-device], MainUI_004); this canvas
  // starts at screen y=60, so local y = screen y − 60.
  static const double _cardX0 = 10;
  static const double _cardStrideX = 155;
  static const double _cardScreenY0 = 66;
  static const double _cardStrideY = 170;
  static const double _cardCenterOffsetX = 77;
  static const double _iconTopOffset = 19;
  static const double _labelCenterOffset = 144.5;
  static const double _contentTop = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final page = selected ~/ GameSystemsScreen.cellsPerPage;
    final start = page * GameSystemsScreen.cellsPerPage;

    for (var slot = 0; slot < GameSystemsScreen.cellsPerPage; slot++) {
      final index = start + slot;
      if (index >= labels.length) break;
      final row = slot ~/ GameSystemsScreen.columns;
      final col = slot % GameSystemsScreen.columns;
      final cardX = _cardX0 + _cardStrideX * col;
      final cardY = _cardScreenY0 + _cardStrideY * row - _contentTop;
      final centerX = cardX + _cardCenterOffsetX;
      final isSelected = index == selected;

      // Centered-canvas convention (see main menu painter): the card
      // asset's whole canvas centered on the cell anchor — identical to
      // the measured top-left for Silky's 154x170.
      canvas.drawImageCentered(
        isSelected ? cardFocused : cardNormal,
        Offset(centerX, cardY + _cardStrideY / 2),
      );

      final icon = icons[index];
      if (icon != null) {
        canvas.drawImageTopLeft(icon, Offset(centerX - icon.width / 2, cardY + _iconTopOffset));
      }

      final painter = OnionCanvasOps.layoutOnionText(
        labels[index],
        style: OnionFontStyle(font: '', size: fontSize, color: isSelected ? selectedColor : color),
        fontFamily: fontFamily,
      );
      painter.paint(
        canvas,
        Offset(centerX - painter.width / 2, cardY + _labelCenterOffset - painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GameSystemsPainter oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.labels != labels ||
        oldDelegate.icons != icons ||
        oldDelegate.cardNormal != cardNormal ||
        oldDelegate.cardFocused != cardFocused;
  }
}
