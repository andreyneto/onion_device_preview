import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../core/mock_data.dart';
import '../core/theme_config.dart';
import '../device/device_state.dart';
import 'pop_menu_screen.dart';
import 'theme_render_context.dart';
import 'widgets/onion_canvas.dart';
import 'widgets/status_indicators.dart';
import 'widgets/theme_footer.dart';
import 'widgets/theme_header.dart';

/// The Game Switcher (Menu from anywhere): the last played games as
/// full-screen screenshots you page through with left/right.
///
/// Unlike MainUI this screen is **open source**
/// (`Onion/src/gameSwitcher/`), so every coordinate here is [SRC], read
/// off `gs_render.h` / `gameSwitcher.c` — see `docs/spec-1a1.md` §13.
/// Layer order matches the firmware's own render loop
/// (`gameSwitcher.c:109-151`):
///
///   1. black fill + the game's screenshot, centered
///   2. game name bar: 640x60 above the footer (screen y=360 in the full
///      view, 420 in minimal), black, then the screenshot's own strip,
///      then a 0xBE black veil, then the arrows and the name in white
///   3. footer — `extra/gs-bottom-bar` if the theme ships one, else the
///      standard bar with RESUME/BACK and the game counter
///   4. header — `extra/gs-top-bar` if shipped, else the standard bar;
///      title is "GameSwitcher", or the play time when toggled by Select
///   5. battery (inside the header, so the layers above may cover it)
///   6. the button legend `extra/gs-legend`, top-right, for 5s
///   7. the brightness slider `extra/lum0..10` while it's changing
///   8. the pop menu (Start): Resume / Save / Load / Exit to menu
///
/// Deliberate deviations from the firmware, all cosmetic:
///
/// * The long-game-name marquee (`gameNameScroll*`) isn't animated — the
///   name is clipped to the same 552px band instead, so a golden/preview
///   frame is reproducible.
/// * Screenshots are synthesized per game (see [_romScreenImage]). The
///   device shows real ones from `Saves/CurrentProfile/romScreens/`, which
///   a mocked preview has no source for; a black screen (what the
///   firmware draws with no screenshot) would hide the theme's chrome,
///   which is the whole point of the screen.
/// * Holding Y for fullscreen is a tap on Y here (no long-press plumbing
///   in the preview's input layer); the resulting view mode is identical.
class GameSwitcherScreen extends StatefulWidget {
  const GameSwitcherScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  /// The bar heights the firmware falls back to when the theme ships no
  /// custom bars (`gameSwitcher.c:74-75`).
  static const double defaultBarHeight = 60;

  @override
  State<GameSwitcherScreen> createState() => _GameSwitcherScreenState();
}

class _GameSwitcherScreenState extends State<GameSwitcherScreen> {
  /// `legend_timeout` / `brightness_timeout` (`gs_appState.h:71-73`).
  static const Duration _legendTimeout = Duration(milliseconds: 5000);
  static const Duration _brightnessTimeout = Duration(milliseconds: 2000);

  final Map<int, ui.Image> _romScreens = {};
  Timer? _legendTimer;
  Timer? _brightnessTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.bindScreenHandlers(
      OnionScreenKind.gameSwitcher,
      onConfirm: _resume,
      onCancel: _exitToMenu,
      onStart: _openPopMenu,
      onSelect: widget.controller.cycleGsHeader,
      onX: _confirmRemove,
      onY: widget.controller.toggleGsViewMode,
      onUp: () => _changeBrightness(1),
      onDown: () => _changeBrightness(-1),
      onLeft: () => widget.controller.gsMove(-1),
      onRight: () => widget.controller.gsMove(1),
    );
    if (widget.controller.gsShowLegend) {
      _legendTimer = Timer(_legendTimeout, widget.controller.hideGsLegend);
    }
    _ensureRomScreen(widget.controller.gsIndex);
  }

  @override
  void dispose() {
    _legendTimer?.cancel();
    _brightnessTimer?.cancel();
    widget.controller.unbindScreenHandlers(OnionScreenKind.gameSwitcher);
    for (final image in _romScreens.values) {
      image.dispose();
    }
    super.dispose();
  }

  void _changeBrightness(int delta) {
    widget.controller.setBrightness(widget.controller.brightness + delta);
    _brightnessTimer?.cancel();
    _brightnessTimer = Timer(_brightnessTimeout, widget.controller.hideBrightness);
  }

  void _resume() {
    final game = _game;
    widget.controller.showDialog(
      title: 'Resume',
      message: game == null ? 'No game to resume.' : 'Resuming ${game.name} (mock).',
    );
  }

  void _exitToMenu() => widget.controller.goBack();

  void _openPopMenu() {
    widget.controller.showPopMenu(
      const ['Resume', 'Save', 'Load', 'Exit to menu'],
      onSelect: (index) {
        widget.controller.goBack();
        switch (index) {
          case 0:
            _resume();
          case 1:
            widget.controller.showDialog(title: 'Save', message: 'State saved (mock).');
          case 2:
            widget.controller.showDialog(
              title: 'Load',
              message: 'Loaded slot ${widget.controller.gsSaveSlot + 1} (mock).',
            );
          case 3:
            _exitToMenu();
        }
      },
    );
  }

  void _confirmRemove() {
    if (_game == null) return;
    widget.controller.showDialog(
      title: 'Remove from history',
      message: 'Are you sure you want to\nremove game from history?',
      showHint: true,
    );
  }

  OnionMockSwitcherGame? get _game {
    final games = widget.controller.gsGames;
    if (games.isEmpty) return null;
    return games[widget.controller.gsIndex.clamp(0, games.length - 1)];
  }

  /// Builds this game's stand-in screenshot once and keeps it for the
  /// screen's lifetime.
  Future<void> _ensureRomScreen(int index) async {
    if (_romScreens.containsKey(index)) return;
    final image = await _romScreenImage(index);
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() => _romScreens[index] = image);
  }

  /// A deterministic 640x480 stand-in for a game's screenshot: a two-tone
  /// backdrop with a horizon band and a row of blocks, hue derived from
  /// [index] so paging through the history visibly changes the picture
  /// under the theme's chrome. Mock only — see the class doc.
  static Future<ui.Image> _romScreenImage(int index) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final hue = (210 + index * 47) % 360;
    final sky = HSVColor.fromAHSV(1, hue.toDouble(), 0.45, 0.34).toColor();
    final horizon = HSVColor.fromAHSV(1, hue.toDouble(), 0.55, 0.20).toColor();
    final block = HSVColor.fromAHSV(1, ((hue + 40) % 360).toDouble(), 0.35, 0.62).toColor();

    canvas.drawRect(const Rect.fromLTWH(0, 0, 640, 480), Paint()..color = sky);
    canvas.drawRect(const Rect.fromLTWH(0, 320, 640, 160), Paint()..color = horizon);
    for (var i = 0; i < 6; i++) {
      final height = 40.0 + ((index + i) % 4) * 26;
      canvas.drawRect(
        Rect.fromLTWH(40 + i * 96, 320 - height, 64, height),
        Paint()..color = block,
      );
    }
    return recorder.endRecording().toImage(640, 480);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final ctx = widget.ctx;
    final view = controller.gsViewMode;
    final game = _game;
    _ensureRomScreen(controller.gsIndex);

    final customHeader = ctx.image(ThemeAsset.gsTopBar);
    final customFooter = ctx.image(ThemeAsset.gsBottomBar);
    // getHeightOrDefault (gs_render.h:62-66): a custom bar's own height,
    // and a 1px placeholder means "no bar at all".
    final headerHeight = _barHeight(customHeader);
    final footerHeight = _barHeight(customFooter);

    final popMenuOpen = controller.currentScreen == OnionScreenKind.popMenu;
    final showChrome = view == OnionGsViewMode.normal;
    final showGameName = view != OnionGsViewMode.fullscreen && game != null && !popMenuOpen;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GameSwitcherPainter(
              // No history → no screenshot at all, so the painter falls
              // through to the centered `Empty` art. Keyed off the games
              // list rather than the cache, which outlives the state.
              romScreen: controller.gsGames.isEmpty ? null : _romScreens[controller.gsIndex],
              frame: ctx.config.frame,
              view: view,
              footerHeight: footerHeight,
              showGameName: showGameName,
              gameName: game?.name ?? '',
              showLeftArrow: controller.gsIndex > 0,
              showRightArrow: controller.gsIndex < controller.gsGames.length - 1,
              leftArrow: ctx.image(ThemeAsset.arrowLeftWhite),
              rightArrow: ctx.image(ThemeAsset.arrowRightWhite),
              titleStyle: ctx.config.title,
              titleFontFamily: ctx.fontFamily(ctx.config.title.font),
              emptyBg: game == null ? ctx.image(ThemeAsset.emptyBg) : null,
            ),
          ),
        ),
        if (showChrome && !popMenuOpen) _footer(footerHeight, customFooter),
        if (showChrome) _header(headerHeight, customHeader),
        if (showChrome)
          Positioned.fill(
            child: StatusIndicators(
              batteryIcon: ctx.image(batteryAssetFor(controller.batteryPercent, charging: controller.charging)),
              batteryPercentage: controller.batteryPercent,
              charging: controller.charging,
              batteryStyle: ctx.config.batteryPercentage,
              batteryFontFamily: ctx.fontFamily(ctx.config.batteryPercentage.font),
              // The switcher never draws wifi (guide.txt lists only
              // `power` for this screen).
              batteryCenter: Offset(596, headerHeight / 2),
            ),
          ),
        // Legend and brightness are drawn after the chrome, so they may
        // cover the header — exactly the firmware's order.
        Positioned.fill(
          child: CustomPaint(
            painter: _GameSwitcherOverlayPainter(
              legend: controller.gsShowLegend && view != OnionGsViewMode.fullscreen
                  ? ctx.image(ThemeAsset.gsLegend)
                  : null,
              legendTop: view == OnionGsViewMode.normal ? headerHeight : 0,
              brightness: controller.brightnessChanged ? ctx.image(brightnessAssetFor(controller.brightness)) : null,
              brightnessCenterY: view == OnionGsViewMode.normal ? 240 : 210,
              brightnessTop: view == OnionGsViewMode.normal ? headerHeight : 0,
            ),
          ),
        ),
        if (popMenuOpen) ..._popMenuLayers(headerHeight),
      ],
    );
  }

  static double _barHeight(ui.Image? bar) {
    if (bar == null) return GameSwitcherScreen.defaultBarHeight;
    return bar.height > 1 ? bar.height.toDouble() : 0;
  }

  Widget _header(double height, ui.Image? custom) {
    if (height <= 0) return const SizedBox.shrink();
    final ctx = widget.ctx;
    final title = _title();

    if (custom != null) {
      return Positioned(
        left: 0,
        top: 0,
        child: SizedBox(
          width: 640,
          height: height,
          child: CustomPaint(
            painter: _CustomBarPainter(
              bar: custom,
              title: title,
              titleStyle: ctx.config.title,
              titleFontFamily: ctx.fontFamily(ctx.config.title.font),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: 0,
      top: 0,
      child: ThemeHeader(
        background: ctx.image(ThemeAsset.background),
        bgTitle: ctx.image(ThemeAsset.bgTitle),
        // renderHeader passes show_logo: false (gs_render.h:188).
        showLogo: false,
        title: title,
        titleStyle: ctx.config.title,
        titleFontFamily: ctx.fontFamily(ctx.config.title.font),
      ),
    );
  }

  /// "GameSwitcher", or the play time(s) when Select toggled them on
  /// (`renderHeader`, gs_render.h:155-170).
  String _title() {
    final controller = widget.controller;
    final game = _game;
    if (!controller.gsShowTime || game == null) return 'GameSwitcher';
    final time = OnionMockData.formatPlayTime(game.playSeconds);
    if (!controller.gsShowTotal) return time;
    return '$time / ${OnionMockData.formatPlayTime(OnionMockData.totalPlaySeconds)}';
  }

  Widget _footer(double height, ui.Image? custom) {
    if (height <= 0) return const SizedBox.shrink();
    final ctx = widget.ctx;
    final controller = widget.controller;

    // A custom bottom bar replaces the hints entirely — the firmware
    // doesn't draw icon-A/B or tips-bar-bg over it (guide.txt).
    if (custom != null) {
      return Positioned(
        left: 0,
        top: 480 - height,
        child: RawImage(image: custom, filterQuality: FilterQuality.none),
      );
    }

    final games = controller.gsGames;
    return Positioned(
      left: 0,
      top: 480 - height,
      child: ThemeFooter(
        background: ctx.image(ThemeAsset.background),
        bgFooter: ctx.image(ThemeAsset.bgFooter),
        buttonAIcon: ctx.image(ThemeAsset.buttonA),
        buttonBIcon: ctx.image(ThemeAsset.buttonB),
        hintLabelA: 'RESUME',
        hintLabelB: 'BACK',
        showButtonB: true,
        hideLabels: controller.forceHideLabels ?? ctx.config.hideLabels.hints,
        hintStyle: ctx.config.hint,
        hintFontFamily: ctx.fontFamily(ctx.config.hint.font),
        currentPageColor: ctx.config.currentpage.color,
        totalColor: ctx.config.total.color,
        currentPage: games.isEmpty ? 0 : controller.gsIndex + 1,
        totalPages: games.length,
      ),
    );
  }

  /// The switcher's own pop menu (`gs_popMenu.h` + `pop_menu.h`): panel at
  /// the header's bottom edge, the scrim and the save-state preview only
  /// while "Load" is selected, and a footer with SELECT/BACK plus the
  /// slot counter.
  List<Widget> _popMenuLayers(double headerHeight) {
    final ctx = widget.ctx;
    final controller = widget.controller;
    final loadSelected = controller.selectionFor(OnionScreenKind.popMenu) == 2;

    return [
      PopMenuScreen(
        controller: controller,
        ctx: ctx,
        top: controller.gsViewMode == OnionGsViewMode.normal ? headerHeight : 0,
        showScrim: loadSelected,
        scrimColor: _GameSwitcherPainter.veil,
        preview: loadSelected ? _romScreens[controller.gsIndex] : null,
        onLeft: () => controller.setGsSaveSlot(controller.gsSaveSlot - 1),
        onRight: () => controller.setGsSaveSlot(controller.gsSaveSlot + 1),
      ),
      Positioned(
        left: 0,
        top: 480 - GameSwitcherScreen.defaultBarHeight,
        child: ThemeFooter(
          background: ctx.image(ThemeAsset.background),
          bgFooter: ctx.image(ThemeAsset.bgFooter),
          buttonAIcon: ctx.image(ThemeAsset.buttonA),
          buttonBIcon: ctx.image(ThemeAsset.buttonB),
          hintLabelA: 'SELECT',
          hintLabelB: 'BACK',
          showButtonB: true,
          hideLabels: controller.forceHideLabels ?? ctx.config.hideLabels.hints,
          hintStyle: ctx.config.hint,
          hintFontFamily: ctx.fontFamily(ctx.config.hint.font),
          currentPageColor: ctx.config.currentpage.color,
          totalColor: ctx.config.total.color,
          currentPage: loadSelected ? controller.gsSaveSlot + 1 : null,
          totalPages: loadSelected ? OnionMockData.saveStateSlots : null,
        ),
      ),
    ];
  }
}

/// A theme-provided `gs-top-bar` with the title centered in it.
class _CustomBarPainter extends CustomPainter {
  const _CustomBarPainter({
    required this.bar,
    required this.title,
    required this.titleStyle,
    required this.titleFontFamily,
  });

  final ui.Image bar;
  final String title;
  final OnionFontStyle titleStyle;
  final String titleFontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageTopLeft(bar, Offset.zero);
    final painter = OnionCanvasOps.layoutOnionText(title, style: titleStyle, fontFamily: titleFontFamily);
    // (640 - w)/2, (header_height - h)/2 — gs_render.h:179-180.
    painter.paint(canvas, Offset((640 - painter.width) / 2, (size.height - painter.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _CustomBarPainter oldDelegate) =>
      oldDelegate.bar != bar || oldDelegate.title != title;
}

class _GameSwitcherPainter extends CustomPainter {
  const _GameSwitcherPainter({
    required this.romScreen,
    required this.frame,
    required this.view,
    required this.footerHeight,
    required this.showGameName,
    required this.gameName,
    required this.showLeftArrow,
    required this.showRightArrow,
    required this.leftArrow,
    required this.rightArrow,
    required this.titleStyle,
    required this.titleFontFamily,
    required this.emptyBg,
  });

  final ui.Image? romScreen;
  final OnionFrame frame;
  final OnionGsViewMode view;
  final double footerHeight;
  final bool showGameName;
  final String gameName;
  final bool showLeftArrow;
  final bool showRightArrow;
  final ui.Image? leftArrow;
  final ui.Image? rightArrow;
  final OnionFontStyle titleStyle;
  final String titleFontFamily;
  final ui.Image? emptyBg;

  static const double _barHeight = 60;

  /// The name bar's veil — and the pop menu's scrim, the same surface:
  /// `SDL_FillRect(transparent_bg, 0xBE000000)` (`gameSwitcher.c:62-63`).
  static const Color veil = Color(0xBE000000);

  /// The name is always white, not `title.color` (`gs_render.h:70`).
  static const Color _nameColor = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 640, 480), Paint()..color = const Color(0xFF000000));

    if (romScreen == null) {
      // game_list_len == 0 → the `Empty` art centered (gameSwitcher.c:112-117).
      canvas.drawImageCentered(emptyBg, const Offset(320, 240));
      return;
    }

    // renderCentered (gs_render.h:16-41): in the full view the frame's
    // side borders are cropped off the screenshot and it's shifted right
    // by border_left; otherwise the whole image is centered.
    final borderLeft = view == OnionGsViewMode.normal ? frame.borderLeft.toDouble() : 0.0;
    final borderRight = view == OnionGsViewMode.normal ? frame.borderRight.toDouble() : 0.0;
    final offsetX = (640 - romScreen!.width) / 2;
    final offsetY = (480 - romScreen!.height) / 2;
    canvas.drawImageRegion(
      romScreen,
      from: Rect.fromLTWH(borderLeft, 0, 640 - borderLeft - borderRight, 480),
      to: Rect.fromLTWH(offsetX + borderLeft, offsetY, 640 - borderLeft - borderRight, 480),
    );

    if (!showGameName) return;

    // The bar sits above the footer in the full view, at the very bottom
    // in the minimal one (gs_render.h:85-89).
    final barTop = 480 - _barHeight - (view == OnionGsViewMode.normal ? footerHeight : 0);
    final barWidth = 640 - borderLeft - borderRight;
    final barRect = Rect.fromLTWH(borderLeft, barTop, barWidth, _barHeight);

    canvas.drawRect(barRect, Paint()..color = const Color(0xFF000000));
    canvas.drawImageRegion(romScreen, from: barRect.translate(-offsetX, -offsetY), to: barRect);
    canvas.drawRect(barRect, Paint()..color = veil);

    final arrowLeftWidth = leftArrow?.width.toDouble() ?? 24;
    if (showLeftArrow) {
      canvas.drawImageCentered(leftArrow, Offset(borderLeft + 10 + arrowLeftWidth / 2, barTop + 30));
    }
    if (showRightArrow && rightArrow != null) {
      canvas.drawImageTopLeft(
        rightArrow,
        Offset(630 - borderRight - rightArrow!.width, barTop + 30 - rightArrow!.height / 2),
      );
    }

    // Name centered on the *screen*, never closer to the edges than the
    // arrow gutter, clipped to what's left (gs_render.h:73-74, 133-143).
    final padding = arrowLeftWidth + 20;
    final maxWidth = 640 - 2 * padding;
    final painter = OnionCanvasOps.layoutOnionText(
      gameName,
      style: OnionFontStyle(font: titleStyle.font, size: titleStyle.size, color: _nameColor),
      fontFamily: titleFontFamily,
    );
    final x = painter.width < maxWidth ? (640 - painter.width) / 2 : padding;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(padding, barTop, maxWidth, _barHeight));
    painter.paint(canvas, Offset(x, barTop + 30 - painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GameSwitcherPainter oldDelegate) {
    return oldDelegate.romScreen != romScreen ||
        oldDelegate.view != view ||
        oldDelegate.footerHeight != footerHeight ||
        oldDelegate.showGameName != showGameName ||
        oldDelegate.gameName != gameName ||
        oldDelegate.showLeftArrow != showLeftArrow ||
        oldDelegate.showRightArrow != showRightArrow ||
        oldDelegate.leftArrow != leftArrow ||
        oldDelegate.rightArrow != rightArrow ||
        oldDelegate.emptyBg != emptyBg;
  }
}

/// The legend and the brightness slider — the last things the switcher
/// paints before the pop menu (`renderLegend`/`renderBrightness`).
class _GameSwitcherOverlayPainter extends CustomPainter {
  const _GameSwitcherOverlayPainter({
    required this.legend,
    required this.legendTop,
    required this.brightness,
    required this.brightnessCenterY,
    required this.brightnessTop,
  });

  final ui.Image? legend;
  final double legendTop;
  final ui.Image? brightness;
  final double brightnessCenterY;
  final double brightnessTop;

  @override
  void paint(Canvas canvas, Size size) {
    if (legend != null) {
      // {640 - w, header_height} (gs_render.h:219-220).
      canvas.drawImageTopLeft(legend, Offset(640 - legend!.width.toDouble(), legendTop));
    }
    if (brightness != null) {
      // Vertical slider: hugs the left edge, centered on y=240 (210 in
      // the reduced views). A horizontal one is centered instead
      // (gs_render.h:231-236).
      final vertical = brightness!.height > brightness!.width;
      final offset = vertical
          ? Offset(0, brightnessCenterY - brightness!.height / 2)
          : Offset((640 - brightness!.width) / 2, brightnessTop);
      canvas.drawImageTopLeft(brightness, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _GameSwitcherOverlayPainter oldDelegate) {
    return oldDelegate.legend != legend ||
        oldDelegate.legendTop != legendTop ||
        oldDelegate.brightness != brightness ||
        oldDelegate.brightnessCenterY != brightnessCenterY;
  }
}
