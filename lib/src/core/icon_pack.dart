import 'dart:ui' as ui;

import 'asset_resolver.dart';
import 'theme_bundle.dart';

/// Where an icon-pack icon came from, for the inspector.
enum IconPackSource { theme, defaultPack, missing }

/// One resolved icon-pack entry: the image plus which pack served it.
class ResolvedIcon {
  const ResolvedIcon(this.image, this.source);

  final ui.Image? image;
  final IconPackSource source;

  static const ResolvedIcon none = ResolvedIcon(null, IconPackSource.missing);
}

/// Resolves *icon pack* icons — the console icons on the Game Systems grid
/// and the app icons in the Apps list. These are **not** skin assets: the
/// device serves them from `/mnt/SDCARD/Icons/<pack>/`, and installing a
/// theme that ships an `icons/` dir installs that dir as the active pack
/// (`installTheme.h:205-210`, with per-icon fallback to `Icons/Default`).
/// This resolver reproduces that chain: theme zip's `icons/` → the
/// package's bundled `Default` pack → `null`.
///
/// Names follow `apply_icons.h:104-130`, where the pack's sub-tree is part
/// of the icon name:
///
///   `gba`             → `icons/gba.png`,          selected `icons/sel/gba.png`
///   `app/retroarch`   → `icons/app/retroarch.png`, selected `icons/app/sel/retroarch.png`
///   `rapp/snes9x`     → `icons/rapp/snes9x.png`,   selected `icons/rapp/sel/snes9x.png`
///
/// A pack without the `sel/` variant simply reuses the normal icon — the
/// firmware deletes the config's `iconsel` key in that case
/// (`apply_icons.h:169-172`), so MainUI draws the same image either way.
/// Only 22 of the ~250 community themes ship `sel/` at all.
class IconPackResolver {
  IconPackResolver(this.bundle, {this.applyThemeIcons = true});

  final OnionThemeBundle bundle;

  /// Whether the loaded theme's own `icons/` dir is used at all. The
  /// device asks the same question at install time (ThemeSwitcher's
  /// "apply icons" toggle, `themeSwitcher.c:284-311`, on by default);
  /// `false` renders the theme's skin over the stock `Icons/Default` pack.
  final bool applyThemeIcons;

  final Map<String, ResolvedIcon> _cache = {};
  final Map<String, IconPackSource> _sources = {};

  /// Every lookup so far, keyed by the pack-relative path that actually
  /// served it (e.g. `app/retroarch`, `sel/gba`, or the requested path
  /// when nothing did) — for the inspector.
  Map<String, IconPackSource> get sources => Map.unmodifiable(_sources);

  /// Whether the loaded theme ships an icon pack of its own at all.
  bool get themeHasIconPack => bundle.hasFilesUnder('icons/');

  /// Resolves [name] (see the class doc for the naming scheme). With
  /// [selected], looks for the pack's `sel/` variant first and falls back
  /// to the normal icon.
  Future<ResolvedIcon> resolve(String name, {bool selected = false}) async {
    final key = selected ? _selectedKey(name) : name;
    final cached = _cache[key];
    if (cached != null) return cached;

    if (selected) {
      final sel = await _resolveKey(_selectedKey(name));
      if (sel.image != null) return _cache[key] = sel;
      // No sel/ variant: same image as the unselected row.
      return _cache[key] = await resolve(name);
    }

    final direct = await _resolveKey(name);
    if (direct.image != null) return _cache[key] = direct;

    // `-alt` icon variants: the firmware derives the pack lookup name by
    // cutting the config's icon basename at the first '-'
    // (`apply_icons.h:143-144`), so `gba-alt` resolves to the pack's
    // `gba.png`. Applied only as a fallback here, so names that
    // legitimately contain a hyphen (`pico-8`) still resolve first.
    final base = _basename(name);
    final dash = base.indexOf('-');
    if (dash > 0) {
      final trimmed = _withBasename(name, base.substring(0, dash));
      final alt = await _resolveKey(trimmed);
      if (alt.image != null) return _cache[key] = alt;
    }

    _sources[name] = IconPackSource.missing;
    return _cache[key] = ResolvedIcon.none;
  }

  /// Looks [key] up in the theme's pack, then the bundled Default pack,
  /// recording where it landed (only on a hit — a miss here may still be
  /// served by a fallback lookup, and the caller records the final miss).
  Future<ResolvedIcon> _resolveKey(String key) async {
    final path = 'icons/$key.png';

    if (applyThemeIcons) {
      final fromTheme = await AssetResolver.decode(bundle[path]);
      if (fromTheme != null) {
        _sources[key] = IconPackSource.theme;
        return ResolvedIcon(fromTheme, IconPackSource.theme);
      }
    }

    final fromDefault = await AssetResolver.decode(await AssetResolver.defaultSkinBytesAt(path));
    if (fromDefault != null) {
      _sources[key] = IconPackSource.defaultPack;
      return ResolvedIcon(fromDefault, IconPackSource.defaultPack);
    }

    return ResolvedIcon.none;
  }

  /// `gba` → `sel/gba`; `app/retroarch` → `app/sel/retroarch`.
  static String _selectedKey(String name) {
    final slash = name.lastIndexOf('/');
    if (slash < 0) return 'sel/$name';
    return '${name.substring(0, slash)}/sel/${name.substring(slash + 1)}';
  }

  static String _basename(String name) {
    final slash = name.lastIndexOf('/');
    return slash < 0 ? name : name.substring(slash + 1);
  }

  static String _withBasename(String name, String basename) {
    final slash = name.lastIndexOf('/');
    return slash < 0 ? basename : '${name.substring(0, slash + 1)}$basename';
  }
}
