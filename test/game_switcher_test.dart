import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/screens/game_switcher_screen.dart';
import 'package:onion_device_preview/src/screens/pop_menu_screen.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_footer.dart';
import 'package:onion_device_preview/src/screens/widgets/theme_header.dart';

/// Mounts a full [OnionScreen] on the switcher. The legend's 5s timer is
/// let go in every test (`_settle`) so no pending timer trips the harness.
Future<OnionPreviewController> _openSwitcher(WidgetTester tester) async {
  final controller = OnionPreviewController();
  await tester.runAsync(() async {
    await controller.loadTheme(OnionThemeBundle.defaultTheme());
  });
  controller.resetTo(OnionScreenKind.mainMenu);
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: OnionScreen(controller: controller, zoom: OnionZoom.x1),
  ));
  controller.pressMenu();
  await tester.pump();
  return controller;
}

/// Lets the legend/brightness timers fire.
Future<void> _settle(WidgetTester tester) => tester.pump(const Duration(seconds: 6));

void main() {
  testWidgets('Menu opens the switcher from any screen', (tester) async {
    final controller = await _openSwitcher(tester);

    expect(controller.currentScreen, OnionScreenKind.gameSwitcher);
    expect(find.byType(GameSwitcherScreen), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('left/right page through the history and stop at the ends', (tester) async {
    final controller = await _openSwitcher(tester);

    expect(controller.gsIndex, 0);
    controller.moveLeft();
    expect(controller.gsIndex, 0, reason: 'no wrapping at the first game');

    controller.moveRight();
    controller.moveRight();
    await tester.pump();
    expect(controller.gsIndex, 2);

    // The footer counter tracks the current game.
    final footer = tester.widget<ThemeFooter>(find.byType(ThemeFooter));
    expect(footer.currentPage, 3);
    expect(footer.totalPages, controller.gsGames.length);
    expect(footer.hintLabelA, 'RESUME');

    for (var i = 0; i < 20; i++) {
      controller.moveRight();
    }
    expect(controller.gsIndex, controller.gsGames.length - 1);
    await _settle(tester);
  });

  testWidgets('up/down change brightness instead of a list cursor', (tester) async {
    final controller = await _openSwitcher(tester);
    final initial = controller.brightness;

    controller.moveUp();
    await tester.pump();

    expect(controller.brightness, initial + 1);
    expect(controller.brightnessChanged, isTrue);
    expect(controller.selectionFor(OnionScreenKind.gameSwitcher), 0);

    // The slider hides itself 2s after the last change.
    await tester.pump(const Duration(seconds: 3));
    expect(controller.brightnessChanged, isFalse);
    await _settle(tester);
  });

  testWidgets('Y cycles the view modes, dropping the chrome in fullscreen', (tester) async {
    final controller = await _openSwitcher(tester);

    expect(find.byType(ThemeHeader), findsOneWidget);
    expect(find.byType(ThemeFooter), findsOneWidget);

    controller.pressY();
    await tester.pump();
    expect(controller.gsViewMode, OnionGsViewMode.minimal);
    expect(find.byType(ThemeHeader), findsNothing);
    expect(find.byType(ThemeFooter), findsNothing);

    controller.setGsViewMode(OnionGsViewMode.fullscreen);
    await tester.pump();
    expect(find.byType(ThemeHeader), findsNothing);

    controller.pressY();
    await tester.pump();
    expect(controller.gsViewMode, OnionGsViewMode.normal);
    expect(find.byType(ThemeHeader), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('Select cycles the header between the title and the play times', (tester) async {
    final controller = await _openSwitcher(tester);

    String title() => tester.widget<ThemeHeader>(find.byType(ThemeHeader)).title!;

    expect(title(), 'GameSwitcher');

    // Firmware order from its own initial state (show_time false,
    // show_total true): both off, then time, then time + total.
    controller.pressSelect();
    await tester.pump();
    expect(title(), 'GameSwitcher');

    controller.pressSelect();
    await tester.pump();
    expect(title(), OnionMockData.formatPlayTime(controller.gsGames.first.playSeconds));

    controller.pressSelect();
    await tester.pump();
    expect(title(), contains(' / ${OnionMockData.formatPlayTime(OnionMockData.totalPlaySeconds)}'));
    await _settle(tester);
  });

  testWidgets('Start opens the switcher pop menu below the header', (tester) async {
    final controller = await _openSwitcher(tester);

    controller.pressStart();
    await tester.pump();

    expect(controller.popMenuActions, ['Resume', 'Save', 'Load', 'Exit to menu']);
    final popMenu = tester.widget<PopMenuScreen>(find.byType(PopMenuScreen));
    expect(popMenu.top, GameSwitcherScreen.defaultBarHeight);
    // No dim and no save-state preview until "Load" is the focused row.
    expect(popMenu.showScrim, isFalse);
    expect(popMenu.preview, isNull);
    // The footer switches to the pop menu's own hints.
    expect(tester.widget<ThemeFooter>(find.byType(ThemeFooter)).hintLabelA, 'SELECT');
    await _settle(tester);
  });

  testWidgets('the pop menu dims and previews the save slot on Load', (tester) async {
    final controller = await _openSwitcher(tester);
    controller.pressStart();
    await tester.pump();

    controller.setSelection(OnionScreenKind.popMenu, 2);
    await tester.pump();

    expect(tester.widget<PopMenuScreen>(find.byType(PopMenuScreen)).showScrim, isTrue);
    // Left/right walk the slots while Load is focused.
    final footer = tester.widget<ThemeFooter>(find.byType(ThemeFooter));
    expect(footer.currentPage, 1);
    expect(footer.totalPages, OnionMockData.saveStateSlots);

    controller.moveRight();
    await tester.pump();
    expect(controller.gsSaveSlot, 1);
    await _settle(tester);
  });

  testWidgets('X asks to confirm removing the game from the history', (tester) async {
    final controller = await _openSwitcher(tester);

    controller.pressX();
    await tester.pump();

    // A dialog renders over a full-screen base like the switcher.
    expect(controller.currentScreen, OnionScreenKind.dialog);
    expect(controller.dialogTitle, 'Remove from history');
    expect(find.byType(GameSwitcherScreen), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('B leaves the switcher back to where it was opened from', (tester) async {
    final controller = await _openSwitcher(tester);

    controller.pressB();
    await tester.pump();

    expect(controller.currentScreen, OnionScreenKind.mainMenu);
  });
}
