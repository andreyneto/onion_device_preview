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
  })  : _files = files,
        _activeRootPath = activeRootPath;

  final OnionThemeConfig config;
  final List<ThemeRootInfo> availableRoots;
  final Map<String, Uint8List> _files;
  final String _activeRootPath;

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

  static List<ThemeRootInfo> _findThemeRoots(Map<String, Uint8List> files) {
    final candidates = <String>{''};
    for (final path in files.keys) {
      final slash = path.indexOf('/');
      if (slash > 0) candidates.add('${path.substring(0, slash)}/');
    }

    final roots = <ThemeRootInfo>[];
    for (final candidate in candidates) {
      if (_isJunkPath(candidate)) continue;
      final configPath = '${candidate}config.json';
      final hasSkin = files.keys.any((p) => p.startsWith('${candidate}skin/'));
      if (!hasSkin || !files.containsKey(configPath)) continue;
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
