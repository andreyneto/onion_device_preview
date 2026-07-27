import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../core/mock_data.dart';
import '../core/theme_config.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/onion_canvas.dart';

class _MainMenuTab {
  const _MainMenuTab(this.id, this.label, this.normal, this.focused);

  final String id;
  final String label;
  final ThemeAsset normal;
  final ThemeAsset focused;
}

const _kAllTabs = <_MainMenuTab>[
  _MainMenuTab('recent', 'Recents', ThemeAsset.tabRecentNormal, ThemeAsset.tabRecentFocused),
  _MainMenuTab('favorite', 'Favorites', ThemeAsset.tabFavoriteNormal, ThemeAsset.tabFavoriteFocused),
  _MainMenuTab('game', 'Games', ThemeAsset.tabGameNormal, ThemeAsset.tabGameFocused),
  _MainMenuTab('retroarch', 'RetroArch', ThemeAsset.tabRetroarchNormal, ThemeAsset.tabRetroarchFocused),
  _MainMenuTab('app', 'Apps', ThemeAsset.tabAppNormal, ThemeAsset.tabAppFocused),
  _MainMenuTab('setting', 'Settings', ThemeAsset.tabSettingNormal, ThemeAsset.tabSettingFocused),
];

/// The main menu, drawn at fixed pixel positions measured off the stock
/// MainUI screenshot by template-matching the Silky skin's own assets
/// (see `docs/spec-1a1.md` §3 — all coordinates below are [MEAS] unless
/// noted). This screen is the "1x4 grid" the theme config refers to:
/// `grid.grid1x4` is its label font size, `grid.color`/`selectedcolor`
/// its label colors.
///
/// Screen-space geometry (this widget's canvas starts at screen y=60,
/// so local y = screen y − 60):
///   cards   156x328 at x = 10 + 155·slot, screen y = 66 — same y for
///           focused and normal; the focused "pop" is baked into the
///           `-f` asset itself, never scaled in code
///   labels  centered on card center x, line center at screen y = 288,
///           font grid.font @ grid1x4, selectedcolor/color
///   dots    24x14 at stride 28.5, row centered at x = 316, screen y = 390
///
/// Up to 4 card slots are visible; with more tabs a sliding window keeps
/// the selection visible (window behavior itself is [GUESS] — stock
/// default is exactly 4 tabs so it never scrolls there).
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  List<_MainMenuTab> get _tabs => [
        for (final t in _kAllTabs)
          if ((t.id != 'recent' || widget.controller.showRecents) &&
              (t.id != 'retroarch' || widget.controller.expertMode))
            t,
      ];

  @override
  void initState() {
    super.initState();
    widget.controller.bindScreenHandlers(OnionScreenKind.mainMenu, onConfirm: _activate);
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.mainMenu);
    super.dispose();
  }

  void _activate() {
    final tabs = _tabs;
    if (tabs.isEmpty) return;
    final index = widget.controller.horizontalFor(OnionScreenKind.mainMenu).clamp(0, tabs.length - 1);
    switch (tabs[index].id) {
      case 'recent':
        widget.controller.openGameList(OnionMockData.recentRoms, 'Recents');
      case 'favorite':
        widget.controller.openGameList(OnionMockData.favoriteRoms, 'Favorites');
      case 'game':
        widget.controller.goTo(OnionScreenKind.gameSystems);
      case 'retroarch':
        widget.controller.showDialog(
          title: 'RetroArch',
          message: 'Launch RetroArch directly?',
          showHint: true,
          onConfirm: () => widget.controller.showDialog(title: 'RetroArch', message: 'Launched (mock).'),
        );
      case 'app':
        // Apps are `bg-list-l` (tall) rows with an icon-pack icon, one
        // per installed app — see docs/guide.txt ("Apps") and
        // IconPackResolver.
        widget.controller.openSettingsTree(
          [
            for (final app in OnionMockData.apps)
              OnionMockSimpleItem(app.name, large: true, iconPackName: app.iconName),
          ],
          'Apps',
        );
      case 'setting':
        widget.controller.openSettingsTree(OnionMockData.settings, 'Settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    widget.controller.setColumnCount(OnionScreenKind.mainMenu, tabs.length);
    final selected =
        tabs.isEmpty ? 0 : widget.controller.horizontalFor(OnionScreenKind.mainMenu).clamp(0, tabs.length - 1);

    return CustomPaint(
      size: const Size(640, 360),
      painter: _MainMenuPainter(
        tabs: tabs,
        selected: selected,
        ctx: widget.ctx,
        hideLabels: widget.controller.forceHideLabels ?? widget.ctx.config.hideLabels.icons,
      ),
    );
  }
}

class _MainMenuPainter extends CustomPainter {
  const _MainMenuPainter({
    required this.tabs,
    required this.selected,
    required this.ctx,
    required this.hideLabels,
  });

  final List<_MainMenuTab> tabs;
  final int selected;
  final ThemeRenderContext ctx;
  final bool hideLabels;

  // spec-1a1.md §3 — screen-space constants, converted to this canvas's
  // local space (which starts at screen y=60) in paint().
  static const int _visibleSlots = 4;
  static const double _cardX0 = 10, _cardStride = 155, _cardScreenY = 66;
  static const double _cardCenterOffsetX = 78;
  // Half of the reference card canvas height (Silky's 328): the slot's
  // vertical anchor every theme's card canvas is centered on.
  static const double _cardCanvasHalfHeight = 164;
  static const double _labelScreenCenterY = 288;
  static const double _dotStride = 28.5, _dotRowCenterX = 316, _dotScreenY = 390;
  static const double _contentTop = 60;

  @override
  void paint(Canvas canvas, Size size) {
    if (tabs.isEmpty) return;

    // Sliding window of up to 4 slots keeping the selection visible.
    final visible = tabs.length < _visibleSlots ? tabs.length : _visibleSlots;
    var start = selected - 1;
    final maxStart = tabs.length - visible;
    if (start < 0) start = 0;
    if (start > maxStart) start = maxStart;
    if (selected < start) start = selected;
    if (selected > start + visible - 1) start = selected - visible + 1;

    final grid = ctx.config.grid;
    final labelStyle = OnionFontStyle(font: grid.font, size: grid.grid1x4, color: grid.color);
    final labelStyleSelected = OnionFontStyle(font: grid.font, size: grid.grid1x4, color: grid.selectedColor);
    final fontFamily = ctx.fontFamily(grid.font);

    // MainUI's general blitting convention (proven by the battery/wifi
    // measurements and by "big picture"-style themes whose focused card
    // is larger than the screen): the asset's whole CANVAS is centered
    // on the slot's fixed anchor. For Silky's 156x328 cards this lands
    // exactly on the measured top-left (10+155·slot, 66); a 1104x500
    // banner spills across the screen as its author intended. Cards are
    // painted around the selection so the focused one lands last (on
    // top) — oversized focused cards must cover their neighbours.
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, -_contentTop, 640, 480));
    final slotOrder = List<int>.generate(visible, (s) => s)
      ..sort((a, b) => (start + a == selected ? 1 : 0) - (start + b == selected ? 1 : 0));
    for (final slot in slotOrder) {
      final tabIndex = start + slot;
      final tab = tabs[tabIndex];
      final isSelected = tabIndex == selected;
      final centerX = _cardX0 + _cardStride * slot + _cardCenterOffsetX;
      const centerY = _cardScreenY + _cardCanvasHalfHeight - _contentTop;

      final card = ctx.image(isSelected ? tab.focused : tab.normal) ?? ctx.image(tab.normal);
      canvas.drawImageCentered(card, Offset(centerX, centerY));
    }
    canvas.restore();

    for (var slot = 0; slot < visible; slot++) {
      final tabIndex = start + slot;
      final tab = tabs[tabIndex];
      final isSelected = tabIndex == selected;
      final x = _cardX0 + _cardStride * slot;

      if (!hideLabels) {
        final painter = OnionCanvasOps.layoutOnionText(
          tab.label,
          style: isSelected ? labelStyleSelected : labelStyle,
          fontFamily: fontFamily,
        );
        painter.paint(
          canvas,
          Offset(
            x + _cardCenterOffsetX - painter.width / 2,
            (_labelScreenCenterY - _contentTop) - painter.height / 2,
          ),
        );
      }
    }

    final dotActive = ctx.image(ThemeAsset.dotActive);
    final dotNeutral = ctx.image(ThemeAsset.dotNeutral);
    if (dotActive == null && dotNeutral == null) return;
    final n = tabs.length;
    // Same centered-canvas convention: each dot's canvas centered on its
    // 28.5-stride slot (equals the old top-left math for Silky's 24x14).
    final rowLeft = _dotRowCenterX - (n * _dotStride) / 2;
    for (var i = 0; i < n; i++) {
      final image = i == selected ? (dotActive ?? dotNeutral) : (dotNeutral ?? dotActive);
      canvas.drawImageCentered(
        image,
        Offset((rowLeft + _dotStride * i + _dotStride / 2).roundToDouble(), _dotScreenY + 7 - _contentTop),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MainMenuPainter oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.tabs.length != tabs.length ||
        oldDelegate.hideLabels != hideLabels ||
        oldDelegate.ctx != ctx;
  }
}
