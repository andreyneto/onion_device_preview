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
  });
}
