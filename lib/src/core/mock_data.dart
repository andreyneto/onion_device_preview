/// A game system tab (Recents/Favorites/Games/Apps/Settings in the main
/// menu resolve to one of these, or to [OnionMockData.apps] /
/// [OnionMockData.settings]).
class OnionMockSystem {
  const OnionMockSystem({required this.id, required this.name, required this.roms});

  final String id;
  final String name;
  final List<OnionMockRom> roms;

  /// This system's icon-pack name (see `IconPackResolver`): the id
  /// doubles as the icon filename, exactly like the `Emu/*/config.json`
  /// entries the device reads (`icon: ../../Icons/Default/gba.png`).
  String get iconName => id;
}

class OnionMockRom {
  const OnionMockRom(this.name, {this.isFavorite = false, this.isRecent = false});

  final String name;
  final bool isFavorite;
  final bool isRecent;
}

/// One entry of the Game Switcher's history: a recently played rom with
/// its system and accumulated play time (the device reads these from
/// MainUI's recent list plus the play-activity DB).
class OnionMockSwitcherGame {
  const OnionMockSwitcherGame({
    required this.name,
    required this.systemId,
    required this.playSeconds,
  });

  final String name;
  final String systemId;
  final int playSeconds;
}

class OnionMockApp {
  const OnionMockApp(this.name, this.description, this.iconName);

  final String name;

  /// The `description` field of an app's `config.json`, which MainUI draws
  /// as the row's second line (MainUI_013).
  final String description;

  /// Icon-pack name under the pack's `app/` sub-tree
  /// (`apply_icons.h:104-116`), e.g. `app/retroarch`.
  final String iconName;
}

/// A node in the mocked Settings/Tweaks tree, exercising the same item
/// kinds the firmware's list renderer supports (`render/list.h`): a plain
/// row, a toggle, a left/right multivalue picker, and a submenu.
///
/// A row's leading icon comes from one of two different places, matching
/// the device:
///
/// * [iconSkinName] — a themable icon out of the **skin** (e.g.
///   `icon-brightness-48` → `skin/icon-brightness-48.png`), which is what
///   the real Settings menu draws (MainUI_012 reference screenshot).
/// * [iconPackName] — an **icon pack** name (`IconPackResolver`), which is
///   what the Apps list draws, since each `App/*/config.json` points at
///   `Icons/<pack>/app/<name>.png`.
///
/// `null` on both renders the row without an icon.
sealed class OnionMockSettingsItem {
  const OnionMockSettingsItem(this.label, {this.iconSkinName, this.iconPackName});

  final String label;
  final String? iconSkinName;
  final String? iconPackName;
}

class OnionMockSimpleItem extends OnionMockSettingsItem {
  const OnionMockSimpleItem(
    super.label, {
    this.description,
    super.iconSkinName,
    super.iconPackName,
  });

  /// A second line under the label. Its presence is what makes the row a
  /// tall 90px `bg-list-l` one instead of a 60px `bg-list-s`.
  final String? description;
}

class OnionMockToggleItem extends OnionMockSettingsItem {
  const OnionMockToggleItem(super.label, {this.value = false, super.iconSkinName, super.iconPackName});

  final bool value;
}

class OnionMockMultiValueItem extends OnionMockSettingsItem {
  const OnionMockMultiValueItem(
    super.label, {
    required this.options,
    this.selectedIndex = 0,
    super.iconSkinName,
    super.iconPackName,
  });

  final List<String> options;
  final int selectedIndex;
}

class OnionMockSubmenuItem extends OnionMockSettingsItem {
  const OnionMockSubmenuItem(super.label, {required this.children, super.iconSkinName, super.iconPackName});

  final List<OnionMockSettingsItem> children;
}

/// Mocked device data (game systems, roms, apps, settings) used to
/// populate the preview screens — there's no real console behind this,
/// so everything a theme could plausibly need to render is invented here.
class OnionMockData {
  const OnionMockData._();

  static const List<String> _placeholderTitles = [
    'Retro Quest',
    'Star Raiders II',
    'Pac-Attack',
    'Sky Fortress',
    'The Chronicles of a Very Long Game Title That Should Truncate Nicely',
    'Moto Rush 3',
    'Château de la Lune',
    '耐久レース',
    'Zürich Grand Prix',
    'Jungle Bounce',
    'Neon Drift',
    'Café del Rio',
    'Dungeon Crawler EX',
    '1943: Sky Battalion',
    'Puzzle Panic!',
    'Ghost Manor',
    'Turbo Kickboxing',
    'São Paulo Streets',
    'Mecha Brawlers',
    'Ω Prime',
  ];

  static List<OnionMockRom> _romsFor(String prefix) {
    return List.generate(_placeholderTitles.length, (i) {
      final title = '$prefix ${_placeholderTitles[i]}';
      return OnionMockRom(title, isFavorite: i % 5 == 0, isRecent: i < 3);
    });
  }

  static final List<OnionMockSystem> gameSystems = [
    // Short display names as the device's Game Systems grid shows them
    // (Emu pack shortnames — see MainUI_004/005 reference screenshots);
    // ids double as the icon filenames in the SD Icons pack.
    OnionMockSystem(id: 'gba', name: 'GBA', roms: _romsFor('GBA')),
    OnionMockSystem(id: 'sfc', name: 'SFC', roms: _romsFor('SNES')),
    OnionMockSystem(id: 'ps', name: 'PS1', roms: _romsFor('PS1')),
    OnionMockSystem(id: 'md', name: 'Genesis', roms: _romsFor('MD')),
    OnionMockSystem(id: 'gb', name: 'GB', roms: _romsFor('GB')),
    OnionMockSystem(id: 'gbc', name: 'GBC', roms: _romsFor('GBC')),
    OnionMockSystem(id: 'neogeo', name: 'Neo Geo', roms: _romsFor('NEO')),
    OnionMockSystem(id: 'arcade', name: 'Arcade', roms: _romsFor('ARC')),
  ];

  /// Labels, descriptions and icon names copied verbatim from the real
  /// `App/*/config.json` packages the firmware ships
  /// (`Onion/static/packages/App`), so a theme's own `icons/app/`
  /// overrides land on the names it expects and the rows read like the
  /// device's (MainUI_013).
  static const List<OnionMockApp> apps = [
    OnionMockApp('RetroArch', 'Advanced emulator settings', 'app/retroarch'),
    OnionMockApp('File Explorer', 'DinguxCommander', 'app/commander'),
    OnionMockApp('GameSwitcher', 'Quickly switch games', 'app/gameswitcher'),
    OnionMockApp('Battery Monitor', 'Monitor your battery usage', 'app/battery_monitor'),
    OnionMockApp('Ebook Reader', 'PixelReader v0.6', 'app/ereader'),
    OnionMockApp('Tweaks', 'System tweaks and tools', 'app/tweaks'),
  ];

  /// The Apps tab's rows: `bg-list-l` (tall) with the icon-pack icon and
  /// the app's own description underneath (MainUI_013).
  static List<OnionMockSettingsItem> get appItems => [
        for (final app in apps)
          OnionMockSimpleItem(app.name, description: app.description, iconPackName: app.iconName),
      ];

  /// Every icon-pack name the preview's screens can ask for, resolved up
  /// front by `ThemeRenderContext` so painters stay synchronous.
  static List<String> get iconPackNames => [
        'search',
        for (final system in gameSystems) system.iconName,
        for (final app in apps) app.iconName,
      ];

  static List<OnionMockRom> get recentRoms =>
      gameSystems.expand((s) => s.roms).where((r) => r.isRecent).toList();

  /// The Game Switcher's history: the most recent rom of each system,
  /// with deterministic play times (a preview must render the same way
  /// every run — no wall clock anywhere in this package).
  static List<OnionMockSwitcherGame> get switcherGames => [
        for (var i = 0; i < gameSystems.length; i++)
          OnionMockSwitcherGame(
            name: gameSystems[i].roms.first.name,
            systemId: gameSystems[i].id,
            playSeconds: 1080 + i * 2340,
          ),
      ];

  /// Total time across [switcherGames], for the switcher's "time / total"
  /// header.
  static int get totalPlaySeconds => switcherGames.fold(0, (sum, game) => sum + game.playSeconds);

  /// How many save-state slots the mocked current game has (the switcher's
  /// pop menu pages through them under "Load").
  static const int saveStateSlots = 3;

  /// `str_serializeTime` (`utils/str.c:178-193`): `1h 5m`, `5m 30s`, `42s`.
  static String formatPlayTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds - 3600 * hours) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m ${seconds - 60 * minutes}s';
  }

  static List<OnionMockRom> get favoriteRoms =>
      gameSystems.expand((s) => s.roms).where((r) => r.isFavorite).toList();

  /// Mirrors the device's Settings root (MainUI_012): Shutdown,
  /// Brightness 07/10, WIFI, then deeper entries — with the themable
  /// skin icons the real menu uses.
  static const List<OnionMockSettingsItem> settings = [
    OnionMockSimpleItem('Shutdown', iconSkinName: 'icon-Shutdown'),
    OnionMockMultiValueItem(
      'Brightness',
      options: ['01/10', '02/10', '03/10', '04/10', '05/10', '06/10', '07/10', '08/10', '09/10', '10/10'],
      selectedIndex: 6,
      iconSkinName: 'icon-brightness-48',
    ),
    OnionMockSubmenuItem('WIFI', iconSkinName: 'icon-setting-wifi', children: [
      OnionMockToggleItem('Enable Wi-Fi', value: true),
      OnionMockSimpleItem('Home-Net-5G', description: 'Connected'),
      OnionMockSimpleItem('Neighbor_WiFi'),
    ]),
    // `color.png` and `sound-icon.png` break the icon-* naming of the rest
    // of the skin, which is why these two rows went icon-less for so long
    // — but the device does draw them (matched against MainUI_012 at x=20).
    OnionMockSubmenuItem('Display', iconSkinName: 'color', children: [
      OnionMockMultiValueItem('Brightness', options: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'], selectedIndex: 6),
      OnionMockToggleItem('Low battery warning', value: true),
    ]),
    OnionMockMultiValueItem(
      'Change language',
      options: ['English', 'Português', '日本語', 'Español'],
      selectedIndex: 0,
      iconSkinName: 'icon-language-48',
    ),
    // MainUI_012 shows this as a multivalue reading 08/20 — not a submenu —
    // with the speaker icon rather than the numbered `icon-volume-08`.
    OnionMockMultiValueItem(
      'Menu sound',
      options: [
        '00/20', '01/20', '02/20', '03/20', '04/20', '05/20', '06/20', //
        '07/20', '08/20', '09/20', '10/20', '11/20', '12/20', '13/20', //
        '14/20', '15/20', '16/20', '17/20', '18/20', '19/20', '20/20',
      ],
      selectedIndex: 8,
      iconSkinName: 'sound-icon',
    ),
    OnionMockToggleItem('Retro Achievements', value: false),
    OnionMockSimpleItem('Device Info', description: 'Miyoo Mini Plus', iconSkinName: 'icon-device-info-48'),
    OnionMockSimpleItem('Factory Reset', iconSkinName: 'icon-factory-reset-48'),
  ];
}
