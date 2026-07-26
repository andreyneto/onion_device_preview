import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../device/device_state.dart';
import '../device/input_mapper.dart';
import '../device/zoom.dart';
import 'boot_screen.dart';
import 'charging_screen.dart';
import 'dialog_screen.dart';
import 'game_list_screen.dart';
import 'game_systems_screen.dart';
import 'main_menu_screen.dart';
import 'pop_menu_screen.dart';
import 'settings_list_screen.dart';
import 'shutdown_screen.dart';
import 'theme_render_context.dart';
import 'widgets/status_indicators.dart';
import 'widgets/theme_footer.dart';
import 'widgets/theme_header.dart';

/// The device's logical 640x480 screen, rendering whichever OnionUI
/// screen [controller.currentScreen] points to. Embeddable on its own
/// (without `MiyooDeviceShell`) in a host app's layout, e.g. a "screen
/// only" mode — [zoom] defaults to filling whatever space the parent
/// gives it ([OnionZoom.fit]), or pick a fixed pixel-perfect multiple.
///
/// Also owns keyboard input via [InputMapper]: focused (auto-focusing
/// itself) and wired regardless of whether it's used standalone or
/// inside a [MiyooDeviceShell], since either way there's exactly one
/// [OnionScreen] per preview.
class OnionScreen extends StatefulWidget {
  const OnionScreen({super.key, required this.controller, this.zoom = OnionZoom.fit});

  final OnionPreviewController controller;
  final OnionZoom zoom;

  static const Size logicalSize = Size(640, 480);

  @override
  State<OnionScreen> createState() => _OnionScreenState();
}

class _OnionScreenState extends State<OnionScreen> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'OnionScreen');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    // Menu is the one button whose meaning never depends on the active
    // screen (every OnionOS screen shares the same quick-switcher), so
    // it's bound once here rather than by each screen widget.
    widget.controller.onMenu = _openGameSwitcherPlaceholder;
    widget.controller.ensureThemeLoaded();
  }

  @override
  void didUpdateWidget(covariant OnionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller.onMenu = null;
      widget.controller.addListener(_onControllerChanged);
      widget.controller.onMenu = _openGameSwitcherPlaceholder;
      widget.controller.ensureThemeLoaded();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.onMenu = null;
    super.dispose();
  }

  void _openGameSwitcherPlaceholder() {
    widget.controller.showDialog(
      title: 'Game Switcher',
      message: 'Not implemented in this preview (see the backlog).',
    );
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // The controller owns theme resolution (T5.2 — atomic loadTheme):
    // renderContext is null only before the very first load lands, and
    // always points at a fully resolved theme afterwards.
    final renderContext = widget.controller.renderContext;
    final content = SizedBox(
      width: OnionScreen.logicalSize.width,
      height: OnionScreen.logicalSize.height,
      child: ColoredBox(
        color: const Color(0xFF000000),
        child: renderContext == null
            ? const SizedBox.shrink()
            : _ScreenChrome(controller: widget.controller, ctx: renderContext),
      ),
    );

    final scale = widget.zoom.multiplier;
    final scaled = scale == null
        ? FittedBox(child: content)
        : SizedBox(
            width: OnionScreen.logicalSize.width * scale,
            height: OnionScreen.logicalSize.height * scale,
            child: Transform.scale(scale: scale, alignment: Alignment.topLeft, child: content),
          );

    // Host-app controls (sliders, switches...) steal keyboard focus when
    // clicked; tapping anywhere on the screen hands it back, so keyboard
    // input keeps working after fiddling with a control panel.
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) =>
          InputMapper(widget.controller).handleKeyEvent(event) ? KeyEventResult.handled : KeyEventResult.ignored,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusNode.requestFocus,
        child: scaled,
      ),
    );
  }
}

/// What a given non-overlay screen needs from the shared header/footer
/// chrome, plus its body widget.
class _ScreenSpec {
  const _ScreenSpec({
    required this.title,
    required this.hintA,
    this.hintB,
    this.currentPage,
    this.totalPages,
    required this.body,
  });

  final String? title;
  final String hintA;
  final String? hintB;
  final int? currentPage;
  final int? totalPages;
  final Widget body;
}

/// Resolves the current navigation stack into a base screen (header +
/// footer chrome, or one of the full-screen boot/charging/shutdown
/// screens) plus an optional dialog/pop-menu overlay on top of it.
class _ScreenChrome extends StatelessWidget {
  const _ScreenChrome({required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  static const _overlayKinds = {OnionScreenKind.dialog, OnionScreenKind.popMenu};
  static const _fullScreenKinds = {OnionScreenKind.boot, OnionScreenKind.charging, OnionScreenKind.shutdown};

  OnionScreenKind get _base {
    final stack = controller.navigationStack;
    for (var i = stack.length - 1; i >= 0; i--) {
      if (!_overlayKinds.contains(stack[i])) return stack[i];
    }
    return OnionScreenKind.mainMenu;
  }

  OnionScreenKind? get _overlay {
    final top = controller.currentScreen;
    return _overlayKinds.contains(top) ? top : null;
  }

  @override
  Widget build(BuildContext context) {
    final base = _base;
    final overlay = _overlay;

    if (_fullScreenKinds.contains(base)) return _fullScreenBody(base);

    final wifiAsset = _wifiAssetFor(controller.wifi);

    // The firmware blits `background` region-by-region in every render
    // function (header strip, list dim, footer strip...) — the net
    // effect is the full 640x480 background under everything. Painting
    // it once here keeps every screen body transparent-over-background
    // like the real thing (Silky's background is NOT black — #24262F).
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _BackgroundPainter(ctx.image(ThemeAsset.background)))),
        _chromeBody(context, base),
        if (overlay != null)
          overlay == OnionScreenKind.dialog
              ? DialogScreen(controller: controller, ctx: ctx)
              : PopMenuScreen(controller: controller, ctx: ctx),
        // With a pop menu open, the device re-renders the footer above
        // the scrim with OK/CANCEL and no page counter (MainUI_008).
        if (overlay == OnionScreenKind.popMenu)
          Positioned(
            left: 0,
            top: 420,
            child: ThemeFooter(
              background: ctx.image(ThemeAsset.background),
              bgFooter: ctx.image(ThemeAsset.bgFooter),
              buttonAIcon: ctx.image(ThemeAsset.buttonA),
              buttonBIcon: ctx.image(ThemeAsset.buttonB),
              hintLabelA: 'OK',
              hintLabelB: 'CANCEL',
              showButtonB: true,
              hideLabels: controller.forceHideLabels ?? ctx.config.hideLabels.hints,
              hintStyle: ctx.config.hint,
              hintFontFamily: ctx.fontFamily(ctx.config.hint.font),
            ),
          ),
        // Battery/wifi are the topmost layer — MainUI draws them last,
        // above overlays and their scrims (MainUI_008), and a theme's
        // icon canvas may spill far outside the header (win98 parks its
        // battery in the taskbar via a 982x900 canvas).
        Positioned.fill(
          child: StatusIndicators(
            batteryIcon: ctx.image(batteryAssetFor(controller.batteryPercent, charging: controller.charging)),
            batteryPercentage: controller.batteryPercent,
            charging: controller.charging,
            batteryStyle: ctx.config.batteryPercentage,
            batteryFontFamily: ctx.fontFamily(ctx.config.batteryPercentage.font),
            wifiIcon: wifiAsset == null ? null : ctx.image(wifiAsset),
          ),
        ),
      ],
    );
  }

  Widget _fullScreenBody(OnionScreenKind base) {
    return switch (base) {
      OnionScreenKind.boot => BootScreen(controller: controller, ctx: ctx),
      OnionScreenKind.charging => ChargingScreen(controller: controller, ctx: ctx),
      OnionScreenKind.shutdown => ShutdownScreen(controller: controller, ctx: ctx),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _chromeBody(BuildContext context, OnionScreenKind base) {
    final config = ctx.config;
    final spec = _specFor(base);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemeHeader(
          background: ctx.image(ThemeAsset.background),
          bgTitle: ctx.image(ThemeAsset.bgTitle),
          logo: ctx.image(ThemeAsset.logo),
          showLogo: base == OnionScreenKind.mainMenu,
          title: spec.title,
          titleStyle: config.title,
          titleFontFamily: ctx.fontFamily(config.title.font),
        ),
        Expanded(
          child: SizedBox(
            width: OnionScreen.logicalSize.width,
            child: spec.body,
          ),
        ),
        ThemeFooter(
          background: ctx.image(ThemeAsset.background),
          bgFooter: ctx.image(ThemeAsset.bgFooter),
          buttonAIcon: ctx.image(ThemeAsset.buttonA),
          buttonBIcon: ctx.image(ThemeAsset.buttonB),
          hintLabelA: spec.hintA,
          hintLabelB: spec.hintB,
          showButtonB: spec.hintB != null,
          hideLabels: controller.forceHideLabels ?? config.hideLabels.hints,
          hintStyle: config.hint,
          hintFontFamily: ctx.fontFamily(config.hint.font),
          currentPageColor: config.currentpage.color,
          totalColor: config.total.color,
          currentPage: spec.currentPage,
          totalPages: spec.totalPages,
        ),
      ],
    );
  }

  _ScreenSpec _specFor(OnionScreenKind base) {
    return switch (base) {
      // Stock shows "B BACK" on the main menu too (spec-1a1.md §3.5),
      // even though there's nowhere to go back to.
      OnionScreenKind.mainMenu => _ScreenSpec(
          title: null,
          hintA: 'SELECT',
          hintB: 'BACK',
          body: MainMenuScreen(controller: controller, ctx: ctx),
        ),
      OnionScreenKind.gameList => _ScreenSpec(
          title: controller.gameTitle,
          hintA: 'SELECT',
          hintB: 'BACK',
          currentPage: controller.gameRoms.isEmpty ? 0 : controller.selectionFor(OnionScreenKind.gameList) + 1,
          totalPages: controller.gameRoms.length,
          body: GameListScreen(controller: controller, ctx: ctx),
        ),
      // The device shows "page/pages" (e.g. 1/3) in the footer here
      // (MainUI_004), not "cell/cells".
      OnionScreenKind.gameSystems => _ScreenSpec(
          title: 'Games',
          hintA: 'SELECT',
          hintB: 'BACK',
          currentPage:
              controller.horizontalFor(OnionScreenKind.gameSystems) ~/ GameSystemsScreen.cellsPerPage + 1,
          totalPages: GameSystemsScreen.pageCount,
          body: GameSystemsScreen(controller: controller, ctx: ctx),
        ),
      OnionScreenKind.settingsList => _ScreenSpec(
          title: controller.settingsTitle,
          hintA: 'SELECT',
          hintB: 'BACK',
          body: SettingsListScreen(controller: controller, ctx: ctx),
        ),
      // Boot/charging/shutdown never reach here (handled by
      // _fullScreenBody); dialog/popMenu are only ever an overlay, never
      // the resolved base.
      _ => const _ScreenSpec(title: null, hintA: '', body: SizedBox.shrink()),
    };
  }

  ThemeAsset? _wifiAssetFor(OnionWifiState wifi) {
    return switch (wifi) {
      OnionWifiState.off => null,
      OnionWifiState.locked => ThemeAsset.wifiLocked,
      OnionWifiState.signal1 => ThemeAsset.wifiSignal1,
      OnionWifiState.signal2 => ThemeAsset.wifiSignal2,
      OnionWifiState.signal3 => ThemeAsset.wifiSignal3,
      OnionWifiState.signal4 => ThemeAsset.wifiSignal4,
    };
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter(this.background);

  final ui.Image? background;

  @override
  void paint(Canvas canvas, Size size) {
    if (background == null) return;
    canvas.drawImage(background!, Offset.zero, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => oldDelegate.background != background;
}
