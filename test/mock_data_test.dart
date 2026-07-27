import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

void main() {
  group('OnionMockData', () {
    test('has ~8 game systems with ~20 roms each', () {
      expect(OnionMockData.gameSystems.length, 8);
      for (final system in OnionMockData.gameSystems) {
        expect(system.roms.length, greaterThanOrEqualTo(20));
      }
    });

    test('rom names vary in length and script, to exercise truncation/rendering', () {
      final names = OnionMockData.gameSystems.first.roms.map((r) => r.name).toList();

      expect(names.any((n) => n.length > 50), isTrue);
      expect(names.any((n) => n.length < 20), isTrue);
      expect(names.any((n) => n.runes.any((r) => r > 0x2000)), isTrue);
    });

    test('recentRoms and favoriteRoms are non-empty subsets', () {
      expect(OnionMockData.recentRoms, isNotEmpty);
      expect(OnionMockData.favoriteRoms, isNotEmpty);
      expect(OnionMockData.recentRoms.every((r) => r.isRecent), isTrue);
      expect(OnionMockData.favoriteRoms.every((r) => r.isFavorite), isTrue);
    });

    test('apps has a handful of entries', () {
      expect(OnionMockData.apps.length, greaterThanOrEqualTo(4));
    });

    test('settings tree includes a toggle, a multivalue and a submenu', () {
      final flatLabels = <String>{};
      void collect(List<OnionMockSettingsItem> items) {
        for (final item in items) {
          flatLabels.add(item.label);
          if (item is OnionMockSubmenuItem) collect(item.children);
        }
      }

      collect(OnionMockData.settings);

      expect(OnionMockData.settings.whereType<OnionMockSubmenuItem>(), isNotEmpty);
      expect(OnionMockData.settings.whereType<OnionMockMultiValueItem>(), isNotEmpty);
      expect(
        OnionMockData.settings.whereType<OnionMockSubmenuItem>().first.children.whereType<OnionMockToggleItem>(),
        isNotEmpty,
      );
    });

    test('every app carries an icon-pack name under app/', () {
      for (final app in OnionMockData.apps) {
        expect(app.iconName, startsWith('app/'), reason: app.name);
      }
      expect(OnionMockData.iconPackNames, containsAll(OnionMockData.apps.map((a) => a.iconName)));
    });

    test('switcher history is one game per system, with a matching total', () {
      final games = OnionMockData.switcherGames;

      expect(games.length, OnionMockData.gameSystems.length);
      expect(OnionMockData.totalPlaySeconds, games.fold<int>(0, (sum, g) => sum + g.playSeconds));
    });

    test('formatPlayTime matches str_serializeTime', () {
      // utils/str.c:178-193 — seconds under a minute, then m/s, then h/m.
      expect(OnionMockData.formatPlayTime(42), '42s');
      expect(OnionMockData.formatPlayTime(330), '5m 30s');
      expect(OnionMockData.formatPlayTime(3900), '1h 5m');
      // The C code's `nTime >= 60` branch with exactly 60s.
      expect(OnionMockData.formatPlayTime(60), '1m 0s');
    });
  });
}
