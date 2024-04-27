import 'dart:math';

import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/onion_preview.dart';
import 'package:onion_device_preview/src/onion_preview_controller.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class MiyooDevice extends StatelessWidget {

  final OnionTheme? theme;

  MiyooDevice(this.theme, {super.key});

  final controller = OnionPreviewController();

  Widget buildScreen() => Positioned(
      left: 12,
      right: 12,
      top: 10,
      bottom: 480,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.black87, borderRadius: BorderRadius.circular(12)),
      ));

  Widget buildPreview() =>
      Positioned(left: 27, top: 24, right: 27, child: OnionPreview(controller, theme));

  Widget buildBody(ColorScheme colors) => Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
      );

  Widget buildActionButton(ColorScheme colors) => Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
            color: colors.primary, borderRadius: BorderRadius.circular(46)),
      );

  Widget buildB(colors) {
    return Positioned(
      top: 774,
      left: 478,
      child: buildActionButton(colors),
    );
  }

  Widget buildA(colors) {
    return Positioned(
      top: 683,
      left: 569,
      child: buildActionButton(colors),
    );
  }

  Widget buildY(colors) {
    return Positioned(
      top: 683,
      left: 387,
      child: buildActionButton(colors),
    );
  }

  Widget buildX(colors) {
    return Positioned(
      top: 592,
      left: 478,
      child: buildActionButton(colors),
    );
  }

  Widget buildDpad(ColorScheme colors) {
    return Positioned(
      top: 610,
      left: 45,
      child: SizedBox.square(
        dimension: 235,
        child: Stack(
          children: [
            Positioned(
              left: 74,
              top: 74,
              child: Container(
                width: 87,
                height: 87,
                color: colors.secondary,
              ),
            ),
            Positioned(
              left: 75,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: InkWell(
                  onTap: controller.up,
                  child: Container(
                    width: 85,
                    height: 75,
                    color: colors.secondary,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 75,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: InkWell(
                  onTap: controller.down,
                  child: Container(
                    width: 85,
                    height: 75,
                    color: colors.secondary,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 75,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16),
                ),
                child: InkWell(
                  onTap: controller.right,
                  child: Container(
                    width: 75,
                    height: 85,
                    color: colors.secondary,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 75,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: InkWell(
                  onTap: controller.left,
                  child: Container(
                    width: 75,
                    height: 85,
                    color: colors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenu(ColorScheme colors) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 352,
      child: Center(
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
              color: colors.secondary, borderRadius: BorderRadius.circular(46)),
        ),
      ),
    );
  }

  Widget buildStart(colors) {
    return Positioned(
      bottom: 50,
      left: 200,
      child: buildPill(colors),
    );
  }

  Widget buildSelect(colors) {
    return Positioned(
      bottom: 50,
      left: 310,
      child: buildPill(colors),
    );
  }

  Widget buildPill(ColorScheme colors) {
    return Transform.rotate(
      angle: -pi / 5,
      child: Container(
        width: 100,
        height: 30,
        decoration: BoxDecoration(
            color: colors.secondary, borderRadius: BorderRadius.circular(46)),
      ),
    );
  }

  Widget buildSound() {
    return Positioned(
      top: 870,
      right: 50,
      child: Transform.rotate(
        angle: pi / 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.filled(
            4,
            Container(
              width: 80,
              height: 10,
              decoration: BoxDecoration(
                  color: Colors.black12, borderRadius: BorderRadius.circular(46)),
            ),
          ).expand((c) => [c, const SizedBox(height: 20,)]).toList()
            ..removeLast(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: FittedBox(
        child: SizedBox(
          width: 694,
          height: 999,
          child: Stack(
            children: [
              buildBody(colors),
              buildScreen(),
              buildDpad(colors),
              buildMenu(colors),
              buildStart(colors),
              buildSelect(colors),
              buildA(colors),
              buildB(colors),
              buildX(colors),
              buildY(colors),
              buildPreview(),
              buildSound(),
            ],
          ),
        ),
      ),
    );
  }
}
