import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'theme_config.dart';

/// Raised when a zip's bytes don't contain a recognizable OnionUI theme
/// (no `config.json` + `skin/` found at any candidate root), or when the
/// bytes aren't a valid zip archive at all.
class InvalidThemeZipException implements Exception {
  const InvalidThemeZipException(this.message);

  final String message;

  @override
  String toString() => 'InvalidThemeZipException: $message';
}

/// The exact `config.json` firmware ships as the built-in "Silky" theme
/// (`Onion/static/build/miyoo/app/config.json`), used by
/// [OnionThemeBundle.defaultTheme].
const Map<String, dynamic> _kSilkyConfigJson = {
  'name': 'Silky',
  'author': 'DiMo',
  'description': '[Onion default theme]',
  'hideIconTitle': false,
  'batteryPercentage': {'visible': true, 'color': '#FFFFFF', 'onleft': true},
  'title': {'font': '/mnt/SDCARD/miyoo/app/Exo-2-Bold-Italic_Universal.ttf', 'size': 25, 'color': '#FFFFFF'},
  'hint': {'font': '/mnt/SDCARD/miyoo/app/Exo-2-Bold-Italic_Universal.ttf', 'size': 40, 'color': '#FFFFFF'},
  'currentpage': {'color': '#FFFFFF'},
  'total': {'color': '#FFFFFF'},
  'grid': {
    'font': '/mnt/SDCARD/miyoo/app/Exo-2-Bold-Italic_Universal.ttf',
    'grid1x4': 25,
    'grid3x4': 18,
    'color': '#686868',
    'selectedcolor': '#FFFFFF',
  },
  'list': {'font': '/mnt/SDCARD/miyoo/app/wqy-microhei.ttc', 'size': 25, 'color': '#FFFFFF'},
};

/// One theme root found inside a zip: either the zip's own root (a single
/// theme zipped directly) or a top-level directory (a themed subfolder, or
/// one entry of a "theme pack" zip with several themes side by side).
class ThemeRootInfo {
  const ThemeRootInfo({required this.path, required this.config, this.rawConfigJson});

  /// `''` for the zip root, otherwise a top-level directory ending in `/`
  /// (e.g. `'Blueprint by Aemiii91/'`).
  final String path;

  final OnionThemeConfig config;

  /// The decoded `config.json` exactly as the theme shipped it, before
  /// defaults were applied — `null` if the file was missing or malformed.
  /// Lets `ThemeInspector` tell which values the theme actually set apart
  /// from firmware defaults/fallbacks.
  final Map<String, dynamic>? rawConfigJson;

  /// A name to show in a theme picker: the theme's own `name`, else its
  /// directory name, else a generic label.
  String get displayName {
    if (config.name.isNotEmpty) return config.name;
    if (path.isEmpty) return 'Theme';
    return path.substring(0, path.length - 1);
  }
}

/// A theme extracted from a zip's bytes, held entirely in memory.
///
/// Use [OnionThemeBundle.defaultTheme] for the built-in "Silky" skin, or
/// [OnionThemeBundle.fromZipBytes] to load a user-provided theme zip. A zip
/// containing several themes side by side ("theme packs") is exposed via
/// [availableRoots]; pick one with [withRoot].
class OnionThemeBundle {
  const OnionThemeBundle._({
    required this.config,
    required this.availableRoots,
    required Map<String, Uint8List> files,
    required String activeRootPath,
    bool allowAssetlessRoot = false,
  })  : _files = files,
        _activeRootPath = activeRootPath,
        _allowAssetlessRoot = allowAssetlessRoot;

  final OnionThemeConfig config;
  final List<ThemeRootInfo> availableRoots;
  final Map<String, Uint8List> _files;
  final String _activeRootPath;

  /// Whether this bundle's roots may consist of a `config.json` alone.
  /// Carried along by [withFiles] so an in-progress theme doesn't stop
  /// being a theme the moment its config is edited.
  final bool _allowAssetlessRoot;

  /// Whether the zip contained more than one theme (a "theme pack").
  bool get isPack => availableRoots.length > 1;

  /// The active root's path, matching one of [availableRoots]' `path`.
  String get activeRootPath => _activeRootPath;

  /// The active root's decoded `config.json` as shipped (no defaults
  /// applied), or `null` if it was missing/malformed. See
  /// [ThemeRootInfo.rawConfigJson].
  Map<String, dynamic>? get rawConfigJson =>
      availableRoots.firstWhere((r) => r.path == _activeRootPath).rawConfigJson;

  factory OnionThemeBundle.defaultTheme() {
    final config = OnionThemeConfig.fromJson(_kSilkyConfigJson);
    return OnionThemeBundle._(
      config: config,
      availableRoots: [ThemeRootInfo(path: '', config: config, rawConfigJson: _kSilkyConfigJson)],
      files: const {},
      activeRootPath: '',
    );
  }

  /// Extracts a theme zip's bytes in memory and locates every theme root
  /// (a directory containing both `config.json` and a `skin/` folder).
  /// Defaults to the first root found; use [withRoot] to switch when
  /// [isPack] is true.
  ///
  /// Throws [InvalidThemeZipException] if the bytes aren't a valid zip, or
  /// no theme root is found in it.
  factory OnionThemeBundle.fromZipBytes(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw InvalidThemeZipException('Not a valid zip file: $e');
    }

    final files = <String, Uint8List>{};
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = _normalizePath(entry.name);
      if (name.isEmpty || _isJunkPath(name)) continue;
      final content = entry.content;
      files[name] = content is Uint8List ? content : Uint8List.fromList(content as List<int>);
    }

    final roots = _findThemeRoots(files);
    if (roots.isEmpty) {
      throw const InvalidThemeZipException(
        'No theme found in zip (expected a config.json next to a skin/ folder, '
        'either at the zip root or one directory level down).',
      );
    }

    final activeRoot = roots.first;
    return OnionThemeBundle._(
      config: activeRoot.config,
      availableRoots: roots,
      files: files,
      activeRootPath: activeRoot.path,
    );
  }

  /// Builds a bundle straight from an in-memory file map, skipping the zip
  /// round-trip — for editors that hold a theme's files as bytes and need
  /// to re-render after every change.
  ///
  /// Keys are paths relative to the zip root, exactly as
  /// [OnionThemeBundle.fromZipBytes] would have stored them (e.g.
  /// `'Blueprint by Aemiii91/skin/bg-title.png'`, or `'skin/bg-title.png'`
  /// for a theme at the root). Root detection, junk filtering and path
  /// normalization behave identically.
  ///
  /// [activeRootPath] picks one of the detected roots; when omitted (or
  /// unknown) the first one wins, matching [fromZipBytes].
  ///
  /// [allowAssetlessRoot] accepts a directory holding a `config.json` with
  /// no `skin/` next to it. That is a legitimate theme — every asset in the
  /// format is optional, and the firmware falls back to the factory theme
  /// for whatever is missing — but it is off by default: when scanning
  /// someone else's zip, a stray `config.json` in an unrelated directory
  /// would otherwise register as a theme. Turn it on when *authoring*, so
  /// a theme that starts empty stays valid until its first asset exists.
  ///
  /// Throws [InvalidThemeZipException] if no theme root is found.
  factory OnionThemeBundle.fromFiles(
    Map<String, Uint8List> files, {
    String? activeRootPath,
    bool allowAssetlessRoot = false,
  }) {
    final normalized = <String, Uint8List>{};
    for (final entry in files.entries) {
      final name = _normalizePath(entry.key);
      if (name.isEmpty || _isJunkPath(name)) continue;
      normalized[name] = entry.value;
    }

    final roots = _findThemeRoots(normalized, allowAssetlessRoot: allowAssetlessRoot);
    if (roots.isEmpty) {
      throw InvalidThemeZipException(
        'No theme found in the given files (expected a config.json '
        '${allowAssetlessRoot ? '' : 'next to a skin/ folder, '}'
        'either at the root or one directory level down).',
      );
    }

    final active = roots.firstWhere(
      (r) => r.path == activeRootPath,
      orElse: () => roots.first,
    );
    return OnionThemeBundle._(
      config: active.config,
      availableRoots: roots,
      files: normalized,
      activeRootPath: active.path,
      allowAssetlessRoot: allowAssetlessRoot,
    );
  }

  /// Returns a copy of this bundle with [patch] applied on top of its
  /// files — the incremental counterpart of [OnionThemeBundle.fromFiles].
  ///
  /// Keys are relative to the active root, like [operator []]; a `null`
  /// value deletes the file. Roots are re-detected (so editing a
  /// `config.json` or adding the first `skin/` file takes effect), and the
  /// active root is kept when it survives.
  ///
  /// Throws [InvalidThemeZipException] if the patch leaves no theme root.
  OnionThemeBundle withFiles(Map<String, Uint8List?> patch) {
    if (patch.isEmpty) return this;
    final files = Map<String, Uint8List>.from(_files);
    for (final entry in patch.entries) {
      final key = _resolveKey(entry.key);
      if (entry.value == null) {
        files.remove(key);
      } else {
        files[key] = entry.value!;
      }
    }
    return OnionThemeBundle.fromFiles(
      files,
      activeRootPath: _activeRootPath,
      allowAssetlessRoot: _allowAssetlessRoot,
    );
  }

  /// Every file in the bundle, keyed by its path relative to the zip root
  /// (across *all* roots, not just the active one) — what you'd write back
  /// out to a zip or a directory.
  Map<String, Uint8List> get allFiles => Map.unmodifiable(_files);

  /// Paths of the active root's files, relative to that root (e.g.
  /// `'skin/bg-title.png'`), optionally restricted to those under
  /// [underRelativePrefix]. Sorted, so listings are stable.
  List<String> listFiles({String? underRelativePrefix}) {
    final root = _activeRootPath;
    final prefix = underRelativePrefix ?? '';
    final result = <String>[];
    for (final path in _files.keys) {
      if (!path.startsWith(root)) continue;
      final relative = path.substring(root.length);
      if (relative.isEmpty || !relative.startsWith(prefix)) continue;
      result.add(relative);
    }
    result.sort();
    return result;
  }

  String _resolveKey(String relativePath) {
    final name = _normalizePath(relativePath);
    return _activeRootPath.isEmpty ? name : '$_activeRootPath$name';
  }

  /// Returns a copy of this bundle scoped to a different root from
  /// [availableRoots] (identified by its [ThemeRootInfo.path]), without
  /// re-extracting the zip.
  OnionThemeBundle withRoot(String rootPath) {
    final root = availableRoots.firstWhere(
      (r) => r.path == rootPath,
      orElse: () => throw ArgumentError('Unknown theme root: $rootPath'),
    );
    return OnionThemeBundle._(
      config: root.config,
      availableRoots: availableRoots,
      files: _files,
      activeRootPath: root.path,
      allowAssetlessRoot: _allowAssetlessRoot,
    );
  }

  /// Raw bytes for a path relative to the active root (e.g.
  /// `'skin/bg-title.png'`), or `null` if the zip doesn't have it.
  Uint8List? operator [](String relativePath) {
    final key = _activeRootPath.isEmpty ? relativePath : '$_activeRootPath$relativePath';
    return _files[key];
  }

  /// Whether the active root contains any file under [relativePrefix]
  /// (e.g. `'icons/'` — whether the theme ships an icon pack at all).
  bool hasFilesUnder(String relativePrefix) {
    final prefix = _activeRootPath.isEmpty ? relativePrefix : '$_activeRootPath$relativePrefix';
    return _files.keys.any((path) => path.startsWith(prefix));
  }

  static List<ThemeRootInfo> _findThemeRoots(
    Map<String, Uint8List> files, {
    bool allowAssetlessRoot = false,
  }) {
    final candidates = <String>{''};
    for (final path in files.keys) {
      final slash = path.indexOf('/');
      if (slash > 0) candidates.add('${path.substring(0, slash)}/');
    }

    final roots = <ThemeRootInfo>[];
    for (final candidate in candidates) {
      if (_isJunkPath(candidate)) continue;
      final configPath = '${candidate}config.json';
      if (!files.containsKey(configPath)) continue;
      if (!allowAssetlessRoot &&
          !files.keys.any((p) => p.startsWith('${candidate}skin/'))) {
        continue;
      }
      final rawJson = _decodeConfigAt(files, configPath);
      roots.add(ThemeRootInfo(
        path: candidate,
        config: rawJson == null ? OnionThemeConfig.defaults() : OnionThemeConfig.fromJson(rawJson),
        rawConfigJson: rawJson,
      ));
    }

    roots.sort((a, b) {
      if (a.path.isEmpty != b.path.isEmpty) return a.path.isEmpty ? -1 : 1;
      return a.path.compareTo(b.path);
    });
    return roots;
  }

  static Map<String, dynamic>? _decodeConfigAt(Map<String, Uint8List> files, String configPath) {
    try {
      final json = jsonDecode(utf8.decode(files[configPath]!));
      if (json is Map<String, dynamic>) return json;
    } catch (_) {
      // Malformed config.json: the theme root is still valid, it just
      // renders with firmware defaults.
    }
    return null;
  }

  static String _normalizePath(String rawName) {
    var name = rawName.replaceAll('\\', '/');
    while (name.startsWith('/')) {
      name = name.substring(1);
    }
    return name;
  }

  static bool _isJunkPath(String path) {
    return path.startsWith('__MACOSX/') || path.endsWith('.DS_Store');
  }
}
