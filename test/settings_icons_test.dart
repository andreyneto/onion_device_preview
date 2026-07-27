import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/settings_list_screen.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_list_item.dart';

/// Mounts the settings/apps list for [items] and returns its rendered rows.
Future<List<ThemeListItem>> _rows(
  WidgetTester tester,
  OnionPreviewController controller,
  List<OnionMockSettingsItem> items,
  String title,
) async {
  await tester.runAsync(() async {
    if (controller.renderContext == null) {
      await controller.loadTheme(OnionThemeBundle.defaultTheme());
    }
    controller.resetTo(OnionScreenKind.mainMenu);
    controller.openSettingsTree(items, title);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 640,
          height: 360,
          child: SettingsListScreen(controller: controller, ctx: controller.renderContext!),
        ),
      ),
    ));
    await Future<void>.delayed(const Duration(seconds: 1));
    await tester.pump();
  });
  return tester.widgetList<ThemeListItem>(find.byType(ThemeListItem)).toList();
}

List<OnionMockSettingsItem> get _appItems => OnionMockData.appItems;

void main() {
  testWidgets('settings rows receive their skin icons', (tester) async {
    final controller = OnionPreviewController();

    final rows = await _rows(tester, controller, OnionMockData.settings, 'Settings');

    expect(rows.first.icon, isNotNull, reason: 'Shutdown row must carry icon-Shutdown');
  });

  testWidgets('app rows receive icon-pack icons and are tall bg-list-l rows', (tester) async {
    final controller = OnionPreviewController();

    final rows = await _rows(tester, controller, _appItems, 'Apps');

    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row.icon, isNotNull, reason: '${row.label} must carry its icons/app/<name> icon');
      expect(row.large, isTrue, reason: 'the Apps list uses bg-list-l rows (docs/guide.txt)');
    }
  });

  testWidgets('app rows fall back to the Default pack when the theme icons are off', (tester) async {
    final controller = OnionPreviewController();
    await tester.runAsync(() => controller.setApplyThemeIcons(false));

    final rows = await _rows(tester, controller, _appItems, 'Apps');

    // The bundled Default pack still serves every app icon the mock uses.
    expect(rows.every((row) => row.icon != null), isTrue);
    expect(controller.renderContext!.appliedThemeIcons, isFalse);
  });
}
