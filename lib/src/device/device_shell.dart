import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../screens/onion_screen.dart';
import 'device_state.dart';

const _bodyColor = Color(0xFF2B2B33);
const _buttonColor = Color(0xFF3A3A44);
const _pressedColor = Color(0xFF7C5CFC);
const _bezelColor = Color(0xFF000000);

/// A Miyoo Mini/Mini+ device mockup — case, D-pad, A/B/X/Y, Start/
/// Select/Menu — wrapping an [OnionScreen]. The visual layout and
/// coordinates are adapted from this package's pre-rewrite
/// `miyoo_device.dart` prototype (see this repo's git history from
/// before the from-scratch rewrite) — a stylized mockup, not a
/// pixel-measured replica of the real hardware.
///
/// Buttons are clickable here *and* driven by the keyboard — the
/// embedded [OnionScreen] owns its own [InputMapper]-backed focus
/// regardless of whether it's shown standalone or inside this shell.
/// X and Y have no bound action ([OnionPreviewController] doesn't model
/// them — no M3 screen uses them) but are still drawn for physical
/// completeness.
class MiyooDeviceShell extends StatelessWidget {
  const MiyooDeviceShell({super.key, required this.controller});

  final OnionPreviewController controller;

  static const Size logicalSize = Size(694, 999);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: logicalSize.width,
        height: logicalSize.height,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _bodyColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(60),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 12,
              top: 10,
              right: 12,
              height: 509,
              child: DecoratedBox(
                decoration: BoxDecoration(color: _bezelColor, borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            Positioned(
              left: 27,
              top: 24,
              width: 640,
              height: 480,
              child: OnionScreen(controller: controller),
            ),
            _Dpad(controller: controller),
            Positioned(
              left: 0,
              right: 0,
              bottom: 352,
              child: Center(child: _PressableCircle(diameter: 55, onTap: controller.pressMenu)),
            ),
            Positioned(
              bottom: 50,
              left: 310,
              child: Transform.rotate(angle: -math.pi / 5, child: _PressablePill(onTap: controller.pressStart)),
            ),
            Positioned(
              bottom: 50,
              left: 200,
              child: Transform.rotate(angle: -math.pi / 5, child: _PressablePill(onTap: controller.pressSelect)),
            ),
            // X and Y only act on screens that bind them (the Game
            // Switcher does: remove from history / cycle view mode).
            Positioned(top: 592, left: 478, child: _PressableCircle(diameter: 92, onTap: controller.pressX)),
            Positioned(top: 683, left: 387, child: _PressableCircle(diameter: 92, onTap: controller.pressY)),
            Positioned(top: 683, left: 569, child: _PressableCircle(diameter: 92, onTap: controller.pressA)),
            Positioned(top: 774, left: 478, child: _PressableCircle(diameter: 92, onTap: controller.pressB)),
          ],
        ),
      ),
    );
  }
}

class _Dpad extends StatelessWidget {
  const _Dpad({required this.controller});

  final OnionPreviewController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 45,
      top: 610,
      child: SizedBox(
        width: 235,
        height: 235,
        child: Stack(
          children: [
            const Positioned(left: 74, top: 74, child: ColoredBox(color: _buttonColor, child: SizedBox(width: 87, height: 87))),
            Positioned(
              left: 75,
              child: _DpadSegment(
                width: 85,
                height: 75,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                onTap: controller.moveUp,
              ),
            ),
            Positioned(
              left: 75,
              bottom: 0,
              child: _DpadSegment(
                width: 85,
                height: 75,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                onTap: controller.moveDown,
              ),
            ),
            Positioned(
              top: 75,
              right: 0,
              child: _DpadSegment(
                width: 75,
                height: 85,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                onTap: controller.moveRight,
              ),
            ),
            Positioned(
              top: 75,
              child: _DpadSegment(
                width: 75,
                height: 85,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                onTap: controller.moveLeft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DpadSegment extends StatefulWidget {
  const _DpadSegment({required this.width, required this.height, required this.borderRadius, required this.onTap});

  final double width;
  final double height;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  State<_DpadSegment> createState() => _DpadSegmentState();
}

class _DpadSegmentState extends State<_DpadSegment> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: ColoredBox(
          color: _pressed ? _pressedColor : _buttonColor,
          child: SizedBox(width: widget.width, height: widget.height),
        ),
      ),
    );
  }
}

class _PressableCircle extends StatefulWidget {
  const _PressableCircle({required this.diameter, required this.onTap});

  final double diameter;
  final VoidCallback? onTap;

  @override
  State<_PressableCircle> createState() => _PressableCircleState();
}

class _PressableCircleState extends State<_PressableCircle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(color: _pressed ? _pressedColor : _buttonColor, shape: BoxShape.circle),
        child: SizedBox(width: widget.diameter, height: widget.diameter),
      ),
    );
  }
}

class _PressablePill extends StatefulWidget {
  const _PressablePill({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_PressablePill> createState() => _PressablePillState();
}

class _PressablePillState extends State<_PressablePill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _pressed ? _pressedColor : _buttonColor,
          borderRadius: BorderRadius.circular(46),
        ),
        child: const SizedBox(width: 100, height: 30),
      ),
    );
  }
}
