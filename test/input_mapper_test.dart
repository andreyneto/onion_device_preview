import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/device/input_mapper.dart';

KeyDownEvent _down(LogicalKeyboardKey key) =>
    KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyA, logicalKey: key, timeStamp: Duration.zero);

KeyUpEvent _up(LogicalKeyboardKey key) =>
    KeyUpEvent(physicalKey: PhysicalKeyboardKey.keyA, logicalKey: key, timeStamp: Duration.zero);

void main() {
  group('InputMapper', () {
    test('arrows move the current screen horizontal cursor', () {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);
      controller.setColumnCount(OnionScreenKind.mainMenu, 3);
      final mapper = InputMapper(controller);

      expect(mapper.handleKeyEvent(_down(LogicalKeyboardKey.arrowRight)), isTrue);
      expect(controller.horizontalFor(OnionScreenKind.mainMenu), 1);

      expect(mapper.handleKeyEvent(_down(LogicalKeyboardKey.arrowLeft)), isTrue);
      expect(controller.horizontalFor(OnionScreenKind.mainMenu), 0);
    });

    test('X presses confirm (A button), Z backs out (B button)', () {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);
      var confirmed = false;
      controller.bindScreenHandlers(OnionScreenKind.mainMenu, onConfirm: () => confirmed = true);
      final mapper = InputMapper(controller);

      expect(mapper.handleKeyEvent(_down(LogicalKeyboardKey.keyX)), isTrue);
      expect(confirmed, isTrue);

      controller.goTo(OnionScreenKind.settingsList);
      expect(mapper.handleKeyEvent(_down(LogicalKeyboardKey.keyZ)), isTrue);
      expect(controller.currentScreen, OnionScreenKind.mainMenu);
    });

    test('Enter=Start, Shift=Select, Escape=Menu', () {
      final controller = OnionPreviewController(); // starts at boot
      String? fired;
      controller.bindScreenHandlers(
        OnionScreenKind.boot,
        onStart: () => fired = 'start',
        onSelect: () => fired = 'select',
      );
      controller.onMenu = () => fired = 'menu';
      final mapper = InputMapper(controller);

      mapper.handleKeyEvent(_down(LogicalKeyboardKey.enter));
      expect(fired, 'start');
      mapper.handleKeyEvent(_down(LogicalKeyboardKey.shiftLeft));
      expect(fired, 'select');
      mapper.handleKeyEvent(_down(LogicalKeyboardKey.escape));
      expect(fired, 'menu');
    });

    test('Y (A key) and X (S key) are mapped but have no bound action', () {
      final controller = OnionPreviewController();
      final mapper = InputMapper(controller);
      expect(mapper.handleKeyEvent(_down(LogicalKeyboardKey.keyA)), isTrue);
      expect(mapper.handleKeyEvent(_down(LogicalKeyboardKey.keyS)), isTrue);
    });

    test('unmapped keys are not handled', () {
      final controller = OnionPreviewController();
      final mapper = InputMapper(controller);
      expect(mapper.handleKeyEvent(_down(LogicalKeyboardKey.keyQ)), isFalse);
    });

    test('key-up events report handled without re-dispatching the action', () {
      final controller = OnionPreviewController()..resetTo(OnionScreenKind.mainMenu);
      controller.setColumnCount(OnionScreenKind.mainMenu, 3);
      final mapper = InputMapper(controller);

      mapper.handleKeyEvent(_down(LogicalKeyboardKey.arrowRight));
      expect(controller.horizontalFor(OnionScreenKind.mainMenu), 1);

      expect(mapper.handleKeyEvent(_up(LogicalKeyboardKey.arrowRight)), isTrue);
      expect(controller.horizontalFor(OnionScreenKind.mainMenu), 1);
    });
  });
}
