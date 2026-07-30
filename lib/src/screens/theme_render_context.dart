import 'dart:ui' as ui;

import '../core/asset_resolver.dart';
import '../core/font_loader.dart';
import '../core/icon_pack.dart';
import '../core/mock_data.dart';
import '../core/theme_bundle.dart';
import '../core/theme_config.dart';

/// Every asset and font family a loaded theme needs, resolved once
/// up front so painters can stay synchronous. Built via [resolve].
///
/// Also carries the resolution *report* (which assets came from the
/// theme zip vs. the bundled default skin vs. nowhere, and which font
/// paths fell back) so `ThemeInspector` can display it without
/// re-running the pipeline.
class ThemeRenderContext {
  const ThemeRenderContext({
    required this.config,
    required Map<ThemeAsset, ui.Image?> images,
    required Map<String, String> fontFamilies,
    Map<String, ResolvedIcon> packIcons = const {},
    Map<String, ResolvedIcon> selectedPackIcons = const {},
    this.packIconSources = const {},
    this.assetsFoundInTheme = const {},
    this.assetsFromDefaultSkin = const {},
    this.assetsMissing = const {},
    this.fontsFailed = const {},
    this.themeHasIconPack = false,
    this.appliedThemeIcons = true,
  })  : _images = images,
        _fontFamilies = fontFamilies,
        _packIcons = packIcons,
        _selectedPackIcons = selectedPackIcons;

  final OnionThemeConfig config;
  final Map<ThemeAsset, ui.Image?> _images;
  final Map<String, String> _fontFamilies;
  final Map<String, ResolvedIcon> _packIcons;
  final Map<String, ResolvedIcon> _selectedPackIcons;

  /// Assets found in the loaded theme's own zip.
  final Set<ThemeAsset> assetsFoundInTheme;

  /// Assets the theme doesn't ship, served by the bundled default skin.
  final Set<ThemeAsset> assetsFromDefaultSkin;

  /// Assets missing from both the theme and the default skin.
  final Set<ThemeAsset> assetsMissing;

  /// `config.json` font paths that fell back to [kOnionFallbackFontFamily]
  /// (missing from the zip, a `.ttc`, or a decode error).
  final Set<String> fontsFailed;

  /// Whether the loaded theme ships an `icons/` pack of its own.
  final bool themeHasIconPack;

  /// Whether the theme's own icon pack was applied when resolving (see
  /// [IconPackResolver.applyThemeIcons]).
  final bool appliedThemeIcons;

  ui.Image? image(ThemeAsset asset) => _images[asset];

  /// A resolved icon-pack icon (see [IconPackResolver]) — the console
  /// icons on the Game Systems grid and the app icons in the Apps list.
  /// [selected] picks the pack's `sel/` variant when it has one (falling
  /// back to the normal icon, like the device).
  ui.Image? packIcon(String name, {bool selected = false}) =>
      (selected ? _selectedPackIcons[name] : _packIcons[name])?.image;

  /// Where each icon-pack lookup landed, keyed by the pack-relative path
  /// that served it (e.g. `app/retroarch`, `sel/gba`) — for
  /// `ThemeInspector`.
  final Map<String, IconPackSource> packIconSources;

  /// The Flutter font family resolved for a `config.json` font path
  /// (e.g. `config.title.font`). Falls back to the package's default
  /// font if that path was never resolved into this context.
  String fontFamily(String configFontPath) => _fontFamilies[configFontPath] ?? kOnionFallbackFontFamily;

  /// Every `config.json` font path resolved into this context, mapped to
  /// the Flutter font family actually used for it.
  Map<String, String> get fontFamiliesByPath => Map.unmodifiable(_fontFamilies);

  /// Every asset resolved into this context, with the image each one
  /// landed on (`null` where nothing was found).
  Map<ThemeAsset, ui.Image?> get imagesByAsset => Map.unmodifiable(_images);

  /// A copy of this context with individual pieces swapped — the live-edit
  /// path for editors: rasterize the asset you just changed, hand the
  /// resulting [ui.Image] over in [imageOverrides], and repaint without
  /// re-resolving (and re-decoding) the whole skin.
  ///
  /// [imageOverrides] is merged over the current images, so assets you
  /// don't mention keep whatever they resolved to. Every other field
  /// (including the resolution report) is carried over untouched — a
  /// context patched this way still reports where its *originally
  /// resolved* assets came from.
  ThemeRenderContext copyWith({
    OnionThemeConfig? config,
    Map<ThemeAsset, ui.Image?>? imageOverrides,
    Map<String, String>? fontFamilies,
  }) {
    return ThemeRenderContext(
      config: config ?? this.config,
      images: imageOverrides == null || imageOverrides.isEmpty
          ? _images
          : (Map<ThemeAsset, ui.Image?>.from(_images)..addAll(imageOverrides)),
      fontFamilies: fontFamilies ?? _fontFamilies,
      packIcons: _packIcons,
      selectedPackIcons: _selectedPackIcons,
      packIconSources: packIconSources,
      assetsFoundInTheme: assetsFoundInTheme,
      assetsFromDefaultSkin: assetsFromDefaultSkin,
      assetsMissing: assetsMissing,
      fontsFailed: fontsFailed,
      themeHasIconPack: themeHasIconPack,
      appliedThemeIcons: appliedThemeIcons,
    );
  }

  /// Resolves every asset in [assets] (defaults to all of [ThemeAsset]),
  /// every icon-pack icon the mock references, and every distinct font
  /// path the config uses, against [bundle]. Callers rendering a single
  /// screen should pass just the assets that screen needs, to avoid
  /// decoding the whole skin. [applyThemeIcons] mirrors ThemeSwitcher's
  /// install-time "apply icons" choice (see [IconPackResolver]).
  static Future<ThemeRenderContext> resolve(
    OnionThemeBundle bundle, {
    Iterable<ThemeAsset>? assets,
    bool applyThemeIcons = true,
  }) async {
    final assetResolver = AssetResolver(bundle);
    final fontResolver = OnionFontResolver(bundle);
    final iconResolver = IconPackResolver(bundle, applyThemeIcons: applyThemeIcons);
    final config = bundle.config;

    final images = <ThemeAsset, ui.Image?>{};
    for (final asset in assets ?? ThemeAsset.values) {
      images[asset] = await assetResolver.resolve(asset);
    }

    final packIcons = <String, ResolvedIcon>{};
    final selectedPackIcons = <String, ResolvedIcon>{};
    for (final name in OnionMockData.iconPackNames) {
      packIcons[name] = await iconResolver.resolve(name);
      selectedPackIcons[name] = await iconResolver.resolve(name, selected: true);
    }

    final fontPaths = <String>{
      config.title.font,
      config.hint.font,
      config.list.font,
      config.grid.font,
      config.batteryPercentage.font,
    };
    final fontFamilies = <String, String>{};
    for (final path in fontPaths) {
      fontFamilies[path] = await fontResolver.resolveFamily(path);
    }

    return ThemeRenderContext(
      config: config,
      images: images,
      fontFamilies: fontFamilies,
      packIcons: packIcons,
      selectedPackIcons: selectedPackIcons,
      packIconSources: iconResolver.sources,
      themeHasIconPack: iconResolver.themeHasIconPack,
      appliedThemeIcons: applyThemeIcons,
      assetsFoundInTheme: assetResolver.foundInTheme,
      assetsFromDefaultSkin: assetResolver.foundInDefault,
      assetsMissing: assetResolver.missing,
      fontsFailed: fontResolver.failed,
    );
  }
}
