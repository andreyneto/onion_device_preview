import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/settings_list_screen.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_list_item.dart';

void main() {
  testWidgets('settings rows receive their skin icons', (tester) async {
    final controller = OnionPreviewController();
    late ThemeRenderContext ctx;
    await tester.runAsync(() async {
      await controller.loadTheme(OnionThemeBundle.defaultTheme());
      ctx = controller.renderContext!;
      controller.resetTo(OnionScreenKind.mainMenu);
      controller.openSettingsTree(OnionMockData.settings, 'Settings');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
            child: SizedBox(
                width: 640, height: 360, child: SettingsListScreen(controller: controller, ctx: ctx))),
      ));
      await Future<void>.delayed(const Duration(seconds: 1));
      await tester.pump();
    });
    final rows = tester.widgetList<ThemeListItem>(find.byType(ThemeListItem)).toList();
    for (final r in rows) {
      debugPrint('${r.label}: icon=${r.icon != null}');
    }
    expect(rows.first.icon, isNotNull, reason: 'Shutdown row must carry icon-Shutdown');
  });
}
