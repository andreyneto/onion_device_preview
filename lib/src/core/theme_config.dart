import 'dart:ui' show Color;

/// Font path the firmware falls back to when a theme doesn't ship or
/// reference one (`Onion/src/common/theme/load.h:13`).
const String kOnionFallbackFontPath = '/customer/app/Exo-2-Bold-Italic.ttf';

const Color _white = Color(0xFFFFFFFF);
const Color _gridGray = Color(0xFF686868);

/// Horizontal alignment of the battery percentage text relative to its
/// icon. Named to avoid clashing with Flutter's own `TextAlign`.
enum OnionTextAlign { left, center, right }

/// A `{font, size, color}` triple, used by `title`, `hint`, `currentpage`,
/// `total` and `list` in `config.json`. Mirrors `FontStyle_s`
/// (`config.h:43-47`).
class OnionFontStyle {
  const OnionFontStyle({required this.font, required this.size, required this.color});

  final String font;
  final int size;
  final Color color;

  /// Applies `json`'s `font`/`size`/`color` on top of [base], falling back
  /// to [fallback]'s resolved values for anything `json` doesn't set, then
  /// to [base] if there's no fallback either. Mirrors `json_fontStyle`
  /// (`config.h:85-93`), which is called with `dest` pre-seeded to a
  /// firmware default and `fallback` only used when `use_fallbacks` is true.
  factory OnionFontStyle._resolve(
    Map<String, dynamic>? json,
    OnionFontStyle base, {
    OnionFontStyle? fallback,
  }) {
    final font = _string(json, 'font') ?? fallback?.font ?? base.font;
    final size = _int(json, 'size') ?? fallback?.size ?? base.size;
    final color = _color(json, 'color') ?? fallback?.color ?? base.color;
    return OnionFontStyle(font: font, size: size, color: color);
  }
}

/// `hideLabels` — whether icon/tab labels and footer hint labels are
/// hidden. Mirrors `HideLabels_s` (`config.h:38-41`).
class OnionHideLabels {
  const OnionHideLabels({this.icons = false, this.hints = false});

  final bool icons;
  final bool hints;
}

/// `frame` — extra left/right border width. Mirrors `Frame_s`
/// (`config.h:33-36`).
class OnionFrame {
  const OnionFrame({this.borderLeft = 0, this.borderRight = 0});

  final int borderLeft;
  final int borderRight;
}

/// `grid` — font and colors for the game grid. Mirrors `GridStyle_s`
/// (`config.h:49-55`). Note the firmware gives this block no dynamic
/// fallback chain: every field has a static default, independent of
/// `title`.
class OnionGridStyle {
  const OnionGridStyle({
    this.font = kOnionFallbackFontPath,
    this.grid1x4 = 24,
    this.grid3x4 = 18,
    this.color = _gridGray,
    this.selectedColor = _white,
  });

  final String font;
  final int grid1x4;
  final int grid3x4;
  final Color color;
  final Color selectedColor;
}

/// `batteryPercentage` — the battery % text drawn next to the battery
/// icon. Mirrors `BatteryPercentage_s` (`config.h:22-31`).
class OnionBatteryPercentage {
  const OnionBatteryPercentage({
    this.visible = false,
    this.font = kOnionFallbackFontPath,
    this.size = 24,
    this.sizeExplicit = false,
    this.color = _white,
    this.offsetX = 0,
    this.offsetY = 0,
    this.textAlign = OnionTextAlign.left,
    this.fixed = false,
  });

  final bool visible;
  final String font;
  final int size;

  /// Whether the theme's own `config.json` set `size` (vs. the firmware
  /// default of 24). The MainUI top bar draws its percentage smaller
  /// (~18px, measured on device) when the theme doesn't specify one, so
  /// the header needs to tell these cases apart.
  final bool sizeExplicit;

  final Color color;
  final int offsetX;
  final int offsetY;
  final OnionTextAlign textAlign;
  final bool fixed;

  /// Only [size] varies in practice (the header's ~18px default), so that
  /// is all this overrides.
  OnionBatteryPercentage copyWith({int? size}) {
    return OnionBatteryPercentage(
      visible: visible,
      font: font,
      size: size ?? this.size,
      sizeExplicit: sizeExplicit,
      color: color,
      offsetX: offsetX,
      offsetY: offsetY,
      textAlign: textAlign,
      fixed: fixed,
    );
  }
}

/// Parsed representation of a theme's `config.json`, with every field
/// defaulted per the OnionOS firmware (`Onion/src/common/theme/config.h`).
/// Every key is optional; see `plan.md` §5-F2 for the full fallback chain.
class OnionThemeConfig {
  const OnionThemeConfig({
    this.name = '',
    this.author = '',
    this.description = '',
    this.hideLabels = const OnionHideLabels(),
    this.batteryPercentage = const OnionBatteryPercentage(),
    this.frame = const OnionFrame(),
    required this.title,
    required this.hint,
    required this.currentpage,
    required this.total,
    this.grid = const OnionGridStyle(),
    required this.list,
  });

  final String name;
  final String author;
  final String description;
  final OnionHideLabels hideLabels;
  final OnionBatteryPercentage batteryPercentage;
  final OnionFrame frame;
  final OnionFontStyle title;
  final OnionFontStyle hint;
  final OnionFontStyle currentpage;
  final OnionFontStyle total;
  final OnionGridStyle grid;
  final OnionFontStyle list;

  static const _defaultTitle = OnionFontStyle(font: kOnionFallbackFontPath, size: 36, color: _white);
  static const _defaultHint = OnionFontStyle(font: kOnionFallbackFontPath, size: 40, color: _white);
  static const _defaultCurrentpageTotal = OnionFontStyle(font: '', size: 0, color: _white);
  static const _defaultList = OnionFontStyle(font: kOnionFallbackFontPath, size: 24, color: _white);

  factory OnionThemeConfig.defaults() => const OnionThemeConfig(
        title: _defaultTitle,
        hint: _defaultHint,
        currentpage: _defaultCurrentpageTotal,
        total: _defaultCurrentpageTotal,
        list: _defaultList,
      );

  /// Parses a decoded `config.json`. Every field is optional and every
  /// unparseable value (wrong type, malformed hex color, unknown enum
  /// string) is treated as absent rather than thrown — a theme with a
  /// broken `config.json` still renders with firmware defaults.
  factory OnionThemeConfig.fromJson(Map<String, dynamic> json) {
    final name = _string(json, 'name') ?? '';
    final author = _string(json, 'author') ?? '';
    final description = _string(json, 'description') ?? '';

    final hideLabels = _parseHideLabels(json);

    final title = OnionFontStyle._resolve(_object(json, 'title'), _defaultTitle);
    final hint = OnionFontStyle._resolve(_object(json, 'hint'), _defaultHint, fallback: title);
    final currentpage =
        OnionFontStyle._resolve(_object(json, 'currentpage'), _defaultCurrentpageTotal, fallback: hint);
    final total = OnionFontStyle._resolve(_object(json, 'total'), _defaultCurrentpageTotal, fallback: hint);
    final list = OnionFontStyle._resolve(_object(json, 'list'), _defaultList, fallback: title);

    final grid = _parseGrid(json);
    final batteryPercentage = _parseBatteryPercentage(json, hint);
    final frame = _parseFrame(json);

    return OnionThemeConfig(
      name: name,
      author: author,
      description: description,
      hideLabels: hideLabels,
      batteryPercentage: batteryPercentage,
      frame: frame,
      title: title,
      hint: hint,
      currentpage: currentpage,
      total: total,
      grid: grid,
      list: list,
    );
  }

  static OnionHideLabels _parseHideLabels(Map<String, dynamic> json) {
    final hideLabelsJson = _object(json, 'hideLabels');
    if (hideLabelsJson != null) {
      return OnionHideLabels(
        icons: _bool(hideLabelsJson, 'icons') ?? false,
        hints: _bool(hideLabelsJson, 'hints') ?? false,
      );
    }
    // Legacy `hideIconTitle` applies to both icons and hints.
    final legacy = _bool(json, 'hideIconTitle');
    if (legacy != null) {
      return OnionHideLabels(icons: legacy, hints: legacy);
    }
    return const OnionHideLabels();
  }

  static OnionGridStyle _parseGrid(Map<String, dynamic> json) {
    final gridJson = _object(json, 'grid');
    const defaults = OnionGridStyle();
    return OnionGridStyle(
      font: _string(gridJson, 'font') ?? defaults.font,
      grid1x4: _int(gridJson, 'grid1x4') ?? defaults.grid1x4,
      grid3x4: _int(gridJson, 'grid3x4') ?? defaults.grid3x4,
      color: _color(gridJson, 'color') ?? defaults.color,
      selectedColor: _color(gridJson, 'selectedcolor') ?? defaults.selectedColor,
    );
  }

  static OnionBatteryPercentage _parseBatteryPercentage(Map<String, dynamic> json, OnionFontStyle hint) {
    final batteryJson = _object(json, 'batteryPercentage');
    const defaults = OnionBatteryPercentage();

    final textAlignStr = _string(batteryJson, 'textAlign');
    OnionTextAlign textAlign;
    if (textAlignStr != null) {
      textAlign = switch (textAlignStr) {
        'center' => OnionTextAlign.center,
        'right' => OnionTextAlign.right,
        _ => OnionTextAlign.left,
      };
    } else {
      // Legacy `onleft`: true meant the text sits to the right of the icon.
      final legacyOnLeft = _bool(batteryJson, 'onleft');
      textAlign = legacyOnLeft == null
          ? defaults.textAlign
          : (legacyOnLeft ? OnionTextAlign.right : OnionTextAlign.left);
    }

    return OnionBatteryPercentage(
      visible: _bool(batteryJson, 'visible') ?? defaults.visible,
      font: _string(batteryJson, 'font') ?? hint.font,
      size: _int(batteryJson, 'size') ?? defaults.size,
      sizeExplicit: _int(batteryJson, 'size') != null,
      color: _color(batteryJson, 'color') ?? hint.color,
      offsetX: _int(batteryJson, 'offsetX') ?? defaults.offsetX,
      offsetY: _int(batteryJson, 'offsetY') ?? defaults.offsetY,
      textAlign: textAlign,
      fixed: _bool(batteryJson, 'fixed') ?? defaults.fixed,
    );
  }

  static OnionFrame _parseFrame(Map<String, dynamic> json) {
    final frameJson = _object(json, 'frame');
    const defaults = OnionFrame();
    return OnionFrame(
      borderLeft: _int(frameJson, 'border-left') ?? defaults.borderLeft,
      borderRight: _int(frameJson, 'border-right') ?? defaults.borderRight,
    );
  }
}

Map<String, dynamic>? _object(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return value is Map<String, dynamic> ? value : null;
}

String? _string(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return value is String ? value : null;
}

int? _int(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  if (value is int) return value;
  if (value is double) return value.toInt();
  return null;
}

bool? _bool(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  return value is bool ? value : null;
}

/// Parses a `#RRGGBB` or `#AARRGGBB` hex color, ignoring any alpha byte
/// (matches `hex2sdl`, `color.h:7-16`, which always reads the low 24 bits
/// regardless of input width). Unlike the firmware — which happily turns
/// unparseable garbage into a garbage color — a value that isn't valid hex
/// is treated as absent so the field falls back instead, per the parser's
/// tolerance goal (`plan.md` §5-F2).
Color? _color(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  if (value is! String) return null;
  final hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length != 6 && hex.length != 8) return null;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return null;
  final r = (parsed >> 16) & 0xFF;
  final g = (parsed >> 8) & 0xFF;
  final b = parsed & 0xFF;
  return Color.fromARGB(0xFF, r, g, b);
}
