import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import '../core/mock_data.dart';
import '../core/theme_bundle.dart';
import '../screens/theme_render_context.dart';
import 'sound_bank.dart';

/// The screens the OnionUI firmware can render. See `plan.md` §5-F4.
enum OnionScreenKind {
  boot,
  mainMenu,
  gameList,
  gameSystems,
  settingsList,
  gameSwitcher,
  dialog,
  popMenu,
  charging,
  shutdown,
}

/// The Game Switcher's three view modes (`gs_appState.h:9-11`): the full
/// chrome, the game-name bar alone, or nothing but the game's screenshot.
enum OnionGsViewMode { normal, minimal, fullscreen }

/// Mocked Wi-Fi indicator state. There are 6 real skin assets for this
/// (`icon-wifi-{connected,locked,signal-01..04}.png`, see
/// `AssetResolver`/`ThemeAsset`) and no open-source code describing how
/// MainUI picks between them (it's a closed-source binary) — `off` simply
/// means "don't draw a wifi icon", the rest map 1:1 to those assets.
enum OnionWifiState { off, locked, signal1, signal2, signal3, signal4 }

/// Mocked device state driving the preview: theme, battery/wifi/charging,
/// expert mode, clock, per-screen navigation and selection, and the
/// semantic button actions `input_mapper.dart` (M4) will dispatch to.
/// Instantiate one per preview; this holds no global/singleton state.
class OnionPreviewController extends ChangeNotifier {
  OnionPreviewController({OnionThemeBundle? theme})
      : _theme = theme ?? OnionThemeBundle.defaultTheme(),
        _stack = [OnionScreenKind.boot];

  // --- Theme ---

  OnionThemeBundle _theme;
  OnionThemeBundle get theme => _theme;

  ThemeRenderContext? _renderContext;
  int _themeLoadToken = 0;
  bool _themeLoading = false;
  Object? _themeLoadError;

  /// The active theme's fully resolved assets/fonts — what screens render
  /// from. `null` only before the very first load completes.
  ThemeRenderContext? get renderContext => _renderContext;

  /// Whether a [loadTheme] call is currently resolving.
  bool get themeLoading => _themeLoading;

  /// The error of the most recent failed [loadTheme], or `null` if the
  /// last load succeeded. On failure the previously active theme stays
  /// loaded and rendering.
  Object? get themeLoadError => _themeLoadError;

  /// Starts resolving the initial theme if nothing is loaded or loading
  /// yet — called by `OnionScreen` when it mounts (deliberately not from
  /// the constructor, so constructing a controller stays free of async
  /// work). Safe to call repeatedly.
  void ensureThemeLoaded() {
    if (_renderContext == null && !_themeLoading) {
      loadTheme(_theme);
    }
  }

  /// Resolves [theme]'s config, skin assets and fonts, then atomically
  /// swaps it in as the active theme. If resolution fails, the current
  /// theme keeps rendering and the error is exposed via [themeLoadError].
  /// Returns whether the swap happened (also `false` when superseded by a
  /// newer [loadTheme] call racing this one).
  Future<bool> loadTheme(OnionThemeBundle theme) async {
    final token = ++_themeLoadToken;
    _themeLoading = true;
    _themeLoadError = null;
    notifyListeners();
    try {
      final context = await ThemeRenderContext.resolve(theme, applyThemeIcons: _applyThemeIcons);
      if (token != _themeLoadToken) return false;
      _theme = theme;
      _renderContext = context;
      if (_soundEnabled) {
        unawaited(_sounds?.start(theme));
      }
      return true;
    } catch (e) {
      if (token != _themeLoadToken) return false;
      _themeLoadError = e;
      return false;
    } finally {
      if (token == _themeLoadToken) {
        _themeLoading = false;
        notifyListeners();
      }
    }
  }

  // --- Icon pack ---
  //
  // A theme zip may ship an `icons/` pack (68 of the ~250 community
  // themes do) that replaces the SD's console/app icons. Installing it is
  // a separate, opt-out choice on the device (ThemeSwitcher's "apply
  // icons", on by default — `themeSwitcher.c:284-311`), so it's a control
  // here too. Since resolution happens once per theme load, flipping this
  // re-runs the load — the same "reinstall the theme" the device does.

  bool _applyThemeIcons = true;
  bool get applyThemeIcons => _applyThemeIcons;

  Future<void> setApplyThemeIcons(bool value) async {
    if (_applyThemeIcons == value) return;
    _applyThemeIcons = value;
    await loadTheme(_theme);
  }

  // --- Navigation stack ---

  final List<OnionScreenKind> _stack;
  OnionScreenKind get currentScreen => _stack.last;
  List<OnionScreenKind> get navigationStack => List.unmodifiable(_stack);

  void goTo(OnionScreenKind screen) {
    _stack.add(screen);
    _playChangeSfx();
    notifyListeners();
  }

  /// Pops back to the previous screen. A no-op if already at the root
  /// (there's always at least one screen on the stack).
  void goBack() {
    if (_stack.length <= 1) return;
    _stack.removeLast();
    _playChangeSfx();
    notifyListeners();
  }

  /// Replaces the whole stack with a single [screen] (e.g. after boot).
  void resetTo(OnionScreenKind screen) {
    _stack
      ..clear()
      ..add(screen);
    notifyListeners();
  }

  // --- Navigation payloads ---
  //
  // What a given push of gameList/settingsList/dialog/popMenu actually
  // displays isn't encoded in [OnionScreenKind] itself (there's only one
  // enum value per screen *type*, not per dataset) — these hold the
  // small bit of mocked "which dataset" state each screen widget reads
  // once when it mounts. [gameSystems] needs none of its own: it always
  // shows the full, static [OnionMockData.gameSystems] list.

  List<OnionMockRom> _gameRoms = const [];
  String _gameTitle = '';
  List<OnionMockRom> get gameRoms => _gameRoms;
  String get gameTitle => _gameTitle;

  /// Opens (pushes) a rom list for [roms] — used for a chosen system's
  /// roms, and for the Recent/Favorite tabs' cross-system lists.
  void openGameList(List<OnionMockRom> roms, String title) {
    _gameRoms = roms;
    _gameTitle = title;
    resetSelection(OnionScreenKind.gameList);
    goTo(OnionScreenKind.gameList);
  }

  List<_SettingsFrame> _settingsStack = [_SettingsFrame('Settings', OnionMockData.settings)];
  List<OnionMockSettingsItem> get settingsRoot => _settingsStack.last.items;
  String get settingsTitle => _settingsStack.last.title;

  /// Opens (pushes) a settings-style list for [items] (also used to show
  /// the Apps tab, which shares the same row widget), replacing any
  /// submenu depth from a previous visit.
  void openSettingsTree(List<OnionMockSettingsItem> items, String title) {
    _settingsStack = [_SettingsFrame(title, items)];
    resetSelection(OnionScreenKind.settingsList);
    goTo(OnionScreenKind.settingsList);
  }

  /// Descends into a submenu's [items], remembering the current level's
  /// selection so [popSettingsSubmenu] can restore it.
  void pushSettingsSubmenu(List<OnionMockSettingsItem> items, String title) {
    _settingsStack.last.selection = _selection[OnionScreenKind.settingsList] ?? 0;
    _settingsStack.add(_SettingsFrame(title, items));
    _selection[OnionScreenKind.settingsList] = 0;
    notifyListeners();
  }

  /// Pops back to the parent submenu level, restoring its remembered
  /// selection. Returns `false` (a no-op) if already at the root level —
  /// callers should fall back to [goBack] in that case.
  bool popSettingsSubmenu() {
    if (_settingsStack.length <= 1) return false;
    _settingsStack.removeLast();
    _selection[OnionScreenKind.settingsList] = _settingsStack.last.selection;
    notifyListeners();
    return true;
  }

  String _dialogTitle = '';
  String _dialogMessage = '';
  bool _dialogShowHint = false;
  bool _dialogShowProgress = false;
  void Function()? _dialogOnConfirm;
  String get dialogTitle => _dialogTitle;
  String get dialogMessage => _dialogMessage;
  bool get dialogShowHint => _dialogShowHint;
  bool get dialogShowProgress => _dialogShowProgress;
  void Function()? get dialogOnConfirm => _dialogOnConfirm;

  /// Pushes a full-screen dialog overlay. [showHint] draws A/B ("OK"/
  /// "Cancel") hints for a confirmation; leave it false for a plain
  /// informational message dismissed with B. [onConfirm] (only ever
  /// invoked for [showHint] dialogs) fires when A is pressed, before the
  /// dialog closes. [showProgress] shows the animated 1-2-3 progress-dot
  /// row (`theme_renderDialogProgress`) instead of hints — for a mocked
  /// "working…" style dialog.
  void showDialog({
    required String title,
    required String message,
    bool showHint = false,
    bool showProgress = false,
    void Function()? onConfirm,
  }) {
    _dialogTitle = title;
    _dialogMessage = message;
    _dialogShowHint = showHint;
    _dialogShowProgress = showProgress;
    _dialogOnConfirm = onConfirm;
    goTo(OnionScreenKind.dialog);
  }

  List<String> _popMenuActions = const [];
  void Function(int index)? _popMenuOnSelect;
  List<String> get popMenuActions => _popMenuActions;
  void Function(int index)? get popMenuOnSelect => _popMenuOnSelect;

  /// Pushes a contextual pop-menu overlay with up to 4 [actions]; [onSelect]
  /// fires with the chosen action's index when A is pressed (the menu
  /// itself doesn't auto-close — call [goBack] from within [onSelect]).
  void showPopMenu(List<String> actions, {required void Function(int index) onSelect}) {
    assert(actions.isNotEmpty && actions.length <= 4);
    _popMenuActions = actions;
    _popMenuOnSelect = onSelect;
    resetSelection(OnionScreenKind.popMenu);
    goTo(OnionScreenKind.popMenu);
  }

  // --- Game Switcher ---
  //
  // The switcher is its own firmware binary (`Onion/src/gameSwitcher`),
  // and unlike MainUI it's open source — every coordinate and state
  // transition below is [SRC] (see docs/spec-1a1.md §13). It holds the
  // recently played games, one per screenshot, and Menu opens it from
  // anywhere.

  int _gsIndex = 0;
  OnionGsViewMode _gsViewMode = OnionGsViewMode.normal;
  bool _gsShowTime = false;
  bool _gsShowTotal = true;
  bool _gsShowLegend = true;
  int _gsSaveSlot = 0;

  int get gsIndex => _gsIndex;
  OnionGsViewMode get gsViewMode => _gsViewMode;

  /// Whether the header shows the current game's play time instead of the
  /// "GameSwitcher" title, and whether the total is appended
  /// (`action_toggleHeader`, cycled by Select).
  bool get gsShowTime => _gsShowTime;
  bool get gsShowTotal => _gsShowTotal;

  /// Whether the button legend (`extra/gs-legend`) is still showing — the
  /// firmware hides it 5s after entry and remembers that choice
  /// (`gameSwitcher.c:84-88`), so it stays hidden for the session here too.
  bool get gsShowLegend => _gsShowLegend;

  /// Selected save-state slot, shown in the pop menu's "Load" preview.
  int get gsSaveSlot => _gsSaveSlot;

  List<OnionMockSwitcherGame> get gsGames => OnionMockData.switcherGames;

  /// Opens the switcher (what Menu does on every screen).
  void openGameSwitcher() {
    if (currentScreen == OnionScreenKind.gameSwitcher) return;
    goTo(OnionScreenKind.gameSwitcher);
  }

  /// Left/right move by one game and stop at the ends — no wrapping
  /// (`handleUpdateKeystateMain`).
  void gsMove(int delta) {
    final next = (_gsIndex + delta).clamp(0, gsGames.length - 1);
    if (next == _gsIndex) return;
    _gsIndex = next;
    _gsSaveSlot = 0;
    _playChangeSfx();
    notifyListeners();
  }

  void setGsViewMode(OnionGsViewMode value) {
    _gsViewMode = value;
    notifyListeners();
  }

  /// Y toggles between normal and minimal, or restores from fullscreen.
  void toggleGsViewMode() {
    setGsViewMode(switch (_gsViewMode) {
      OnionGsViewMode.normal => OnionGsViewMode.minimal,
      OnionGsViewMode.minimal => OnionGsViewMode.normal,
      // Fullscreen is entered by *holding* Y; a tap restores.
      OnionGsViewMode.fullscreen => OnionGsViewMode.normal,
    });
  }

  /// Select cycles title → play time → play time + total → title, and
  /// brings the legend back (`action_toggleHeader`).
  void cycleGsHeader() {
    if (!_gsShowTime && !_gsShowTotal) {
      _gsShowTime = true;
      _gsShowTotal = false;
    } else if (_gsShowTime && !_gsShowTotal) {
      _gsShowTime = true;
      _gsShowTotal = true;
    } else {
      _gsShowTime = false;
      _gsShowTotal = false;
    }
    _gsShowLegend = true;
    notifyListeners();
  }

  void hideGsLegend() {
    if (!_gsShowLegend) return;
    _gsShowLegend = false;
    notifyListeners();
  }

  void setGsSaveSlot(int slot) {
    final next = slot.clamp(0, OnionMockData.saveStateSlots - 1);
    if (next == _gsSaveSlot) return;
    _gsSaveSlot = next;
    notifyListeners();
  }

  // --- Brightness ---
  //
  // 0-10, shown as a slider overlay (`extra/lum0..10`) for 2s after a
  // change — in the switcher, that's what up/down do
  // (`gameSwitcher.c:90-93`, `handleUpdateKeystateMain`).

  int _brightness = 7;
  bool _brightnessChanged = false;

  int get brightness => _brightness;
  bool get brightnessChanged => _brightnessChanged;

  void setBrightness(int value) {
    _brightness = value.clamp(0, 10);
    _brightnessChanged = true;
    notifyListeners();
  }

  void hideBrightness() {
    if (!_brightnessChanged) return;
    _brightnessChanged = false;
    notifyListeners();
  }

  // --- Sounds ---
  //
  // `sound/bgm.mp3` looped + `sound/change.wav` on navigation, resolved
  // with the same theme → default-skin fallback as skin assets. Lazy: the
  // audio plugin is only touched after the first enable, so constructing
  // a controller (e.g. in tests) never needs it. On web, call
  // [setSoundEnabled] from a user gesture (autoplay policy) — the
  // example's panel toggle qualifies.

  OnionSoundBank? _sounds;
  bool _soundEnabled = false;
  bool get soundEnabled => _soundEnabled;

  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    notifyListeners();
    if (value) {
      _sounds ??= OnionSoundBank();
      await _sounds!.start(_theme);
    } else {
      await _sounds?.stop();
    }
  }

  void _playChangeSfx() {
    final sounds = _sounds;
    if (_soundEnabled && sounds != null) {
      unawaited(sounds.playChange());
    }
  }

  @override
  void dispose() {
    _sounds?.dispose();
    super.dispose();
  }

  // --- Battery / charging ---

  int _batteryPercent = 65;
  int get batteryPercent => _batteryPercent;

  void setBatteryPercent(int value) {
    _batteryPercent = value.clamp(0, 100);
    notifyListeners();
  }

  bool _charging = false;
  bool get charging => _charging;

  void setCharging(bool value) {
    _charging = value;
    notifyListeners();
  }

  // --- Wi-Fi ---

  OnionWifiState _wifi = OnionWifiState.signal4;
  OnionWifiState get wifi => _wifi;

  void setWifi(OnionWifiState value) {
    _wifi = value;
    notifyListeners();
  }

  // --- Expert mode (shows the RetroArch tab on the main menu) ---

  bool _expertMode = false;
  bool get expertMode => _expertMode;

  void setExpertMode(bool value) {
    _expertMode = value;
    notifyListeners();
  }

  // --- Recents tab visibility ---
  //
  // Default false: the factory-default stock main menu shows exactly 4
  // tabs (Favorites/Games/Apps/Settings) — confirmed by the 4 dots in
  // the official Silky preview (`docs/spec-1a1.md` §3.1). OnionOS's own
  // Tweaks toggle for this is "Show recents".

  bool _showRecents = false;
  bool get showRecents => _showRecents;

  void setShowRecents(bool value) {
    _showRecents = value;
    notifyListeners();
  }

  // --- Label visibility override ---
  //
  // Whether tab/hint labels are drawn normally comes from the theme's
  // own `config.hideLabels`; this preview-only override lets a user
  // check both looks without editing the zip. `null` = theme decides,
  // `true`/`false` = force-hide/force-show all labels.

  bool? _forceHideLabels;
  bool? get forceHideLabels => _forceHideLabels;

  void setForceHideLabels(bool? value) {
    _forceHideLabels = value;
    notifyListeners();
  }

  // --- Clock (mocked — not wall-clock time, so previews stay reproducible) ---

  int _clockHour = 14;
  int _clockMinute = 32;
  String get clockText => '${_clockHour.toString().padLeft(2, '0')}:${_clockMinute.toString().padLeft(2, '0')}';

  void setClock(int hour, int minute) {
    _clockHour = hour.clamp(0, 23);
    _clockMinute = minute.clamp(0, 59);
    notifyListeners();
  }

  // --- Per-screen selection cursors ---
  //
  // Two independent bounded axes per screen (vertical for up/down,
  // horizontal for left/right) — e.g. the main menu uses horizontal for
  // its tab bar and vertical for nothing, a settings list uses vertical
  // for the item cursor and ignores horizontal. Which axis a screen uses
  // for what is up to that screen; the controller only tracks the bounds
  // it's told about via [setItemCount]/[setColumnCount].

  final Map<OnionScreenKind, int> _selection = {};
  final Map<OnionScreenKind, int> _itemCount = {};
  final Map<OnionScreenKind, int> _horizontal = {};
  final Map<OnionScreenKind, int> _columnCount = {};

  int selectionFor(OnionScreenKind screen) => _selection[screen] ?? 0;
  int horizontalFor(OnionScreenKind screen) => _horizontal[screen] ?? 0;

  /// Tells the controller how many selectable items [screen] currently
  /// has, so [moveUp]/[moveDown] wrap correctly. Clamps the current
  /// selection if it's now out of range.
  void setItemCount(OnionScreenKind screen, int count) {
    _itemCount[screen] = count;
    _clampIndex(_selection, screen, count);
  }

  /// Tells the controller how many horizontal positions (tabs/columns)
  /// [screen] currently has, so [moveLeft]/[moveRight] wrap correctly.
  void setColumnCount(OnionScreenKind screen, int count) {
    _columnCount[screen] = count;
    _clampIndex(_horizontal, screen, count);
  }

  void _clampIndex(Map<OnionScreenKind, int> index, OnionScreenKind screen, int count) {
    final current = index[screen] ?? 0;
    if (count <= 0) {
      index[screen] = 0;
    } else if (current >= count) {
      index[screen] = count - 1;
    }
  }

  /// Resets [screen]'s vertical cursor to the top — used when a screen
  /// starts showing a fresh dataset (a new rom list, a submenu level)
  /// so a stale selection from whatever was there before doesn't linger.
  void resetSelection(OnionScreenKind screen) {
    _selection[screen] = 0;
  }

  /// Explicitly places [screen]'s vertical cursor at [index], clamped to
  /// its current item count — e.g. restoring a settings submenu's
  /// position when backing out of a deeper level.
  void setSelection(OnionScreenKind screen, int index) {
    final count = _itemCount[screen] ?? 0;
    _selection[screen] = count <= 0 ? 0 : index.clamp(0, count - 1);
    notifyListeners();
  }

  void _moveIndex(Map<OnionScreenKind, int> index, Map<OnionScreenKind, int> counts, int delta) {
    final count = counts[currentScreen] ?? 0;
    if (count <= 0) return;
    final current = index[currentScreen] ?? 0;
    index[currentScreen] = (current + delta) % count;
    _playChangeSfx();
    notifyListeners();
  }

  // --- Grid screens ---
  //
  // A grid (the Game Systems picker) tracks one *linear* cursor on the
  // horizontal axis: left/right move ±1 (wrapping), and up/down jump by
  // ±columns (clamped at the ends) instead of driving the vertical axis.

  final Map<OnionScreenKind, int> _gridColumns = {};

  /// Marks [screen] as a grid with [columns] columns (null reverts it to
  /// the default two-axis behavior).
  void setGridColumns(OnionScreenKind screen, int? columns) {
    if (columns == null) {
      _gridColumns.remove(screen);
    } else {
      _gridColumns[screen] = columns;
    }
  }

  void _moveLinearClamped(int delta) {
    final count = _columnCount[currentScreen] ?? 0;
    if (count <= 0) return;
    final current = _horizontal[currentScreen] ?? 0;
    final next = (current + delta).clamp(0, count - 1);
    if (next == current) return;
    _horizontal[currentScreen] = next;
    _playChangeSfx();
    notifyListeners();
  }

  void moveUp() {
    final handler = _handlers[currentScreen]?.up;
    if (handler != null) return handler();
    final cols = _gridColumns[currentScreen];
    if (cols != null) {
      _moveLinearClamped(-cols);
    } else {
      _moveIndex(_selection, _itemCount, -1);
    }
  }

  void moveDown() {
    final handler = _handlers[currentScreen]?.down;
    if (handler != null) return handler();
    final cols = _gridColumns[currentScreen];
    if (cols != null) {
      _moveLinearClamped(cols);
    } else {
      _moveIndex(_selection, _itemCount, 1);
    }
  }

  void moveLeft() {
    final handler = _handlers[currentScreen]?.left;
    if (handler != null) return handler();
    _moveIndex(_horizontal, _columnCount, -1);
  }

  void moveRight() {
    final handler = _handlers[currentScreen]?.right;
    if (handler != null) return handler();
    _moveIndex(_horizontal, _columnCount, 1);
  }

  // --- Semantic button actions ---
  //
  // What A/Start/Select *do* is entirely screen-specific (open a list,
  // toggle a setting, launch a game...), so each screen widget registers
  // its handlers under its own [OnionScreenKind] and presses dispatch to
  // whatever the *current top screen* registered. Keying by screen — not
  // a single mutable callback — matters because during a base-screen
  // swap the new screen's initState runs before the old screen's dispose
  // (Flutter finalizes the outgoing element at end of frame), so a
  // single slot would be clobbered back to null right after the new
  // screen bound it. It also makes overlays free: a dialog binds under
  // `dialog`, and when it closes, dispatch naturally falls back to what
  // the base screen still has registered.
  //
  // B is the one universal OnionOS convention — it always backs out — so
  // it falls back to [goBack] when the current screen didn't override
  // it. Menu is the opposite: its meaning never depends on the screen
  // (the quick-switcher), so it stays a single global callback.

  final Map<OnionScreenKind, _ScreenHandlers> _handlers = {};

  /// Registers [screen]'s button handlers (replacing any previous ones
  /// for that screen). Call from the screen widget's `initState`.
  ///
  /// [onUp]/[onDown] override the generic selection cursor for screens
  /// where the D-pad's vertical axis means something else (the Game
  /// Switcher maps it to brightness); leave them null for list/grid
  /// screens, which use [moveUp]/[moveDown]'s cursor.
  /// [onLeft]/[onRight] likewise override the horizontal cursor.
  void bindScreenHandlers(
    OnionScreenKind screen, {
    void Function()? onConfirm,
    void Function()? onCancel,
    void Function()? onStart,
    void Function()? onSelect,
    void Function()? onX,
    void Function()? onY,
    void Function()? onUp,
    void Function()? onDown,
    void Function()? onLeft,
    void Function()? onRight,
  }) {
    _handlers[screen] = _ScreenHandlers(
      confirm: onConfirm,
      cancel: onCancel,
      start: onStart,
      select: onSelect,
      x: onX,
      y: onY,
      up: onUp,
      down: onDown,
      left: onLeft,
      right: onRight,
    );
  }

  /// Drops [screen]'s handlers. Call from the screen widget's `dispose`;
  /// only affects that screen's own registration, so a disposing screen
  /// can never unbind its successor.
  void unbindScreenHandlers(OnionScreenKind screen) {
    _handlers.remove(screen);
  }

  void Function()? onMenu;

  void pressA() => _handlers[currentScreen]?.confirm?.call();

  void pressB() {
    final cancel = _handlers[currentScreen]?.cancel;
    if (cancel != null) {
      cancel();
    } else {
      goBack();
    }
  }

  void pressStart() => _handlers[currentScreen]?.start?.call();
  void pressSelect() => _handlers[currentScreen]?.select?.call();

  /// X and Y only do something on screens that ask for them (the Game
  /// Switcher: X removes from history, Y toggles the view mode) — the
  /// shell draws both buttons regardless.
  void pressX() => _handlers[currentScreen]?.x?.call();
  void pressY() => _handlers[currentScreen]?.y?.call();

  void pressMenu() => onMenu?.call();
}

/// One screen's registered button handlers (see
/// [OnionPreviewController.bindScreenHandlers]).
class _ScreenHandlers {
  const _ScreenHandlers({
    this.confirm,
    this.cancel,
    this.start,
    this.select,
    this.x,
    this.y,
    this.up,
    this.down,
    this.left,
    this.right,
  });

  final void Function()? confirm;
  final void Function()? cancel;
  final void Function()? start;
  final void Function()? select;
  final void Function()? x;
  final void Function()? y;
  final void Function()? up;
  final void Function()? down;
  final void Function()? left;
  final void Function()? right;
}

/// One level of settings-submenu depth: the items shown and the
/// breadcrumb title for the header, plus that level's own remembered
/// vertical-cursor position (restored when backing out of a deeper level).
class _SettingsFrame {
  _SettingsFrame(this.title, this.items);

  final String title;
  final List<OnionMockSettingsItem> items;
  int selection = 0;
}
