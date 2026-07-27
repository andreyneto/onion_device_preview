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

class OnionMockApp {
  const OnionMockApp(this.name, this.iconName);

  final String name;

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
    this.large = false,
    super.iconSkinName,
    super.iconPackName,
  });

  final String? description;

  /// Forces the taller 90px `bg-list-l` row even without a description —
  /// the Apps list's row style (`docs/guide.txt`, "Apps" → `bg-list-l`).
  final bool large;
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

  /// Labels and icon names taken from the real `App/*/config.json`
  /// packages the firmware ships (`Onion/static/packages/App`), so a
  /// theme's own `icons/app/` overrides land on the names it expects.
  static const List<OnionMockApp> apps = [
    OnionMockApp('RetroArch', 'app/retroarch'),
    OnionMockApp('File Explorer', 'app/commander'),
    OnionMockApp('GameSwitcher', 'app/gameswitcher'),
    OnionMockApp('Battery Monitor', 'app/battery_monitor'),
    OnionMockApp('Ebook Reader', 'app/ereader'),
    OnionMockApp('Tweaks', 'app/tweaks'),
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
    OnionMockSubmenuItem('Display', children: [
      OnionMockMultiValueItem('Brightness', options: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'], selectedIndex: 6),
      OnionMockToggleItem('Low battery warning', value: true),
    ]),
    OnionMockMultiValueItem(
      'Change language',
      options: ['English', 'Português', '日本語', 'Español'],
      selectedIndex: 0,
      iconSkinName: 'icon-language-48',
    ),
    OnionMockSubmenuItem('Sound', children: [
      OnionMockMultiValueItem('BGM Volume', options: ['Off', 'Low', 'Medium', 'High'], selectedIndex: 2),
      OnionMockToggleItem('Navigation sound', value: true),
    ]),
    OnionMockToggleItem('Retro Achievements', value: false),
    OnionMockSimpleItem('Device Info', description: 'Miyoo Mini Plus', iconSkinName: 'icon-device-info-48'),
    OnionMockSimpleItem('Factory Reset', iconSkinName: 'icon-factory-reset-48'),
  ];
}
