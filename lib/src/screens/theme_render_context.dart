import 'dart:ui' as ui;

import '../core/asset_resolver.dart';
import '../core/font_loader.dart';
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
    this.assetsFoundInTheme = const {},
    this.assetsFromDefaultSkin = const {},
    this.assetsMissing = const {},
    this.fontsFailed = const {},
  })  : _images = images,
        _fontFamilies = fontFamilies;

  final OnionThemeConfig config;
  final Map<ThemeAsset, ui.Image?> _images;
  final Map<String, String> _fontFamilies;

  /// Assets found in the loaded theme's own zip.
  final Set<ThemeAsset> assetsFoundInTheme;

  /// Assets the theme doesn't ship, served by the bundled default skin.
  final Set<ThemeAsset> assetsFromDefaultSkin;

  /// Assets missing from both the theme and the default skin.
  final Set<ThemeAsset> assetsMissing;

  /// `config.json` font paths that fell back to [kOnionFallbackFontFamily]
  /// (missing from the zip, a `.ttc`, or a decode error).
  final Set<String> fontsFailed;

  ui.Image? image(ThemeAsset asset) => _images[asset];

  /// The Flutter font family resolved for a `config.json` font path
  /// (e.g. `config.title.font`). Falls back to the package's default
  /// font if that path was never resolved into this context.
  String fontFamily(String configFontPath) => _fontFamilies[configFontPath] ?? kOnionFallbackFontFamily;

  /// Every `config.json` font path resolved into this context, mapped to
  /// the Flutter font family actually used for it.
  Map<String, String> get fontFamiliesByPath => Map.unmodifiable(_fontFamilies);

  /// Resolves every asset in [assets] (defaults to all of [ThemeAsset])
  /// and every distinct font path the config references, against
  /// [bundle]. Callers rendering a single screen should pass just the
  /// assets that screen needs, to avoid decoding the whole skin.
  static Future<ThemeRenderContext> resolve(OnionThemeBundle bundle, {Iterable<ThemeAsset>? assets}) async {
    final assetResolver = AssetResolver(bundle);
    final fontResolver = OnionFontResolver(bundle);
    final config = bundle.config;

    final images = <ThemeAsset, ui.Image?>{};
    for (final asset in assets ?? ThemeAsset.values) {
      images[asset] = await assetResolver.resolve(asset);
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
      assetsFoundInTheme: assetResolver.foundInTheme,
      assetsFromDefaultSkin: assetResolver.foundInDefault,
      assetsMissing: assetResolver.missing,
      fontsFailed: fontResolver.failed,
    );
  }
}
