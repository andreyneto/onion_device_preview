import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import 'theme_bundle.dart';

/// Logical OnionUI skin assets, mapping to `skin/<name>.png` inside a
/// theme (mirrors `Onion/src/common/theme/resources.h:138-238`, plus the
/// MainUI-only assets this package's screens also need — tabs, game grid
/// cells, thumbnails). `%` in a few firmware filenames (e.g. battery
/// icons) is part of the literal name, not a placeholder.
enum ThemeAsset {
  background('background'),
  bgTitle('bg-title'),
  logo('miyoo-topbar'),
  battery0('power-0%-icon'),
  battery20('power-20%-icon'),
  battery50('power-50%-icon'),
  battery80('power-80%-icon'),
  batteryFull('power-full-icon'),
  batteryCharging('ic-power-charge-100%'),
  bgListSmall('bg-list-s'),
  bgListLarge('bg-list-l'),
  dividerH('div-line-h'),
  progressDot('progress-dot'),
  toggleOn('extra/toggle-on'),
  toggleOff('extra/toggle-off'),
  bgFooter('tips-bar-bg'),
  buttonA('icon-A-54'),
  buttonB('icon-B-54'),
  leftArrow('icon-left-arrow-24'),
  rightArrow('icon-right-arrow-24'),
  popBg('pop-bg'),
  emptyBg('Empty'),
  previewBg('preview-bg'),
  bgPopMenu1('bg-pop-menu-1'),
  bgPopMenu2('bg-pop-menu-2'),
  bgPopMenu3('bg-pop-menu-3'),
  bgPopMenu4('bg-pop-menu-4'),
  dotActive('dot-a'),
  dotNeutral('dot-n'),
  bootScreen('extra/bootScreen'),
  screenOff('extra/Screen_Off'),
  screenOffSave('extra/Screen_Off_Save'),
  lowBat('extra/lowBat'),
  tabRecentNormal('ic-recent-n'),
  tabRecentFocused('ic-recent-f'),
  tabGameNormal('ic-game-n'),
  tabGameFocused('ic-game-f'),
  tabFavoriteNormal('ic-favorite-n'),
  tabFavoriteFocused('ic-favorite-f'),
  tabAppNormal('ic-app-n'),
  tabAppFocused('ic-app-f'),
  tabSettingNormal('ic-setting-n'),
  tabSettingFocused('ic-setting-f'),
  tabRetroarchNormal('ic-retroarch-n'),
  tabRetroarchFocused('ic-retroarch-f'),
  bgGameItemNormal('bg-game-item-n'),
  bgGameItemFocused('bg-game-item-f'),
  thumbDefault('thumb-default'),
  favoriteMark('ic-favorite-mark'),
  wifiConnected('icon-wifi-connected'),
  wifiLocked('icon-wifi-locked'),
  wifiSignal1('icon-wifi-signal-01'),
  wifiSignal2('icon-wifi-signal-02'),
  wifiSignal3('icon-wifi-signal-03'),
  wifiSignal4('icon-wifi-signal-04');

  const ThemeAsset(this.logicalName);

  final String logicalName;

  /// Path relative to a theme's root, e.g. `'skin/bg-title.png'`.
  String get skinPath => 'skin/$logicalName.png';
}

/// Picks the battery icon for a charge level, mirroring
/// `_getBatteryRequest` (`Onion/src/common/theme/render/battery.h:7-20`).
ThemeAsset batteryAssetFor(int percentage, {bool charging = false}) {
  if (charging) return ThemeAsset.batteryCharging;
  if (percentage < 5) return ThemeAsset.battery0;
  if (percentage < 30) return ThemeAsset.battery20;
  if (percentage < 60) return ThemeAsset.battery50;
  if (percentage < 90) return ThemeAsset.battery80;
  return ThemeAsset.batteryFull;
}

/// Resolves [ThemeAsset]s to decoded images, falling back from the loaded
/// [OnionThemeBundle] to the package's bundled default skin, and finally to
/// `null` if neither has it — matching the firmware's own fallback chain
/// (`Onion/src/common/theme/load.h:41-71`), minus the per-profile override
/// step (not applicable to a standalone preview).
///
/// Caches decoded images per [ThemeAsset] and tracks which assets were
/// found in the theme zip vs. only in the default skin vs. missing
/// entirely, for [ThemeInspector].
class AssetResolver {
  AssetResolver(this.bundle);

  final OnionThemeBundle bundle;

  final Map<ThemeAsset, ui.Image?> _cache = {};
  final Set<ThemeAsset> _foundInTheme = {};
  final Set<ThemeAsset> _foundInDefault = {};
  final Set<ThemeAsset> _missing = {};

  /// Assets present in the loaded theme's own zip.
  Set<ThemeAsset> get foundInTheme => Set.unmodifiable(_foundInTheme);

  /// Assets missing from the theme but covered by the bundled default skin.
  Set<ThemeAsset> get foundInDefault => Set.unmodifiable(_foundInDefault);

  /// Assets missing from both the theme and the default skin.
  Set<ThemeAsset> get missing => Set.unmodifiable(_missing);

  Future<ui.Image?> resolve(ThemeAsset asset) async {
    if (_cache.containsKey(asset)) return _cache[asset];

    // A file the theme ships but that fails to decode (truncated/corrupt
    // PNG) falls through to the default skin instead of aborting the
    // whole theme load — one broken file shouldn't kill the preview.
    final themeImage = await _tryDecode(themeBytesAt(asset.skinPath));
    if (themeImage != null) {
      _foundInTheme.add(asset);
      return _cache[asset] = themeImage;
    }

    final defaultImage = await _tryDecode(await _loadDefaultSkinBytes(asset.skinPath));
    if (defaultImage != null) {
      _foundInDefault.add(asset);
      return _cache[asset] = defaultImage;
    }

    _missing.add(asset);
    return _cache[asset] = null;
  }

  /// Resolves an arbitrary skin-relative path through the same zip →
  /// default-skin → `null` fallback chain as [resolve], for assets not
  /// covered by the fixed [ThemeAsset] enum — namely a theme's
  /// variable-length charging animation frames (`extra/chargingStateN`)
  /// and their `chargingState.json` sidecar, whose count isn't known
  /// ahead of time.
  Future<Uint8List?> resolveBytesAt(String relativePath) async {
    return bundle[relativePath] ?? await _loadDefaultSkinBytes(relativePath);
  }

  /// Like [resolveBytesAt], decoded to an image. Not cached (unlike
  /// [resolve]) since callers using this are already doing their own
  /// one-off loading of a variable set of paths.
  Future<ui.Image?> resolveImageAt(String relativePath) async {
    return decode(await resolveBytesAt(relativePath));
  }

  /// A theme-root-relative file straight out of the loaded zip, without
  /// any fallback — for callers that need to know *where* a file came
  /// from (see `IconPackResolver`, which reports per-icon provenance).
  Uint8List? themeBytesAt(String relativePath) => bundle[relativePath];

  /// The same path in the package's bundled default skin, or `null`.
  static Future<Uint8List?> defaultSkinBytesAt(String relativePath) => _loadDefaultSkinBytes(relativePath);

  /// Decodes image [bytes], yielding `null` for `null` or undecodable
  /// input rather than throwing — one corrupt file shouldn't abort a load.
  static Future<ui.Image?> decode(Uint8List? bytes) => _tryDecode(bytes);

  static Future<Uint8List?> _loadDefaultSkinBytes(String relativePath) async {
    try {
      final data = await rootBundle.load('packages/onion_device_preview/assets/default_skin/$relativePath');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> _tryDecode(Uint8List? bytes) async {
    if (bytes == null) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}
