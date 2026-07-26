import 'package:flutter/services.dart';

import 'device_state.dart';

/// Maps physical keyboard keys to Miyoo Mini button semantics, using
/// RetroArch's well-known default keyboard layout (Z/X for B/A, A/S for
/// Y/X) rather than inventing a new one — arrows for the D-pad, Enter
/// for Start, Shift for Select, Escape for Menu. Y and X have no
/// semantic action on [OnionPreviewController] (no screen in this
/// package defines one for them), so they're mapped for physical
/// completeness but don't dispatch anywhere.
///
/// A held key naturally arrives as repeated [KeyDownEvent]s or a
/// [KeyRepeatEvent] depending on platform — both are treated the same
/// here, so holding a direction re-dispatches it just like a real D-pad.
class InputMapper {
  const InputMapper(this.controller);

  final OnionPreviewController controller;

  static final _mappedKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.keyZ,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.escape,
  };

  /// Feed this to a [Focus]/[KeyboardListener]'s `onKeyEvent`. Returns
  /// whether [event] mapped to a button, so callers know whether to
  /// report the event as handled.
  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent) return _mappedKeys.contains(event.logicalKey);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        controller.moveUp();
      case LogicalKeyboardKey.arrowDown:
        controller.moveDown();
      case LogicalKeyboardKey.arrowLeft:
        controller.moveLeft();
      case LogicalKeyboardKey.arrowRight:
        controller.moveRight();
      case LogicalKeyboardKey.keyX:
        controller.pressA();
      case LogicalKeyboardKey.keyZ:
        controller.pressB();
      case LogicalKeyboardKey.enter:
        controller.pressStart();
      case LogicalKeyboardKey.shiftLeft:
      case LogicalKeyboardKey.shiftRight:
        controller.pressSelect();
      case LogicalKeyboardKey.escape:
        controller.pressMenu();
      case LogicalKeyboardKey.keyA:
      case LogicalKeyboardKey.keyS:
        break; // Y / X — no bound action.
      default:
        return false;
    }
    return true;
  }
}
