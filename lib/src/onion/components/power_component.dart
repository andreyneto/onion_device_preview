import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/components/base_component.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class PowerComponent extends StatefulWidget {
  const PowerComponent({super.key});

  @override
  State<PowerComponent> createState() => _PowerComponentState();
}

class _PowerComponentState extends State<PowerComponent> {
  Size size = Size.square(48);

  void listener(info, _) {
    final s = Size(
      info.image.width.toDouble(),
      info.image.height.toDouble(),
    );
    if (size != s) {
      setState(() => size = s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseComponent(
      x: 584 - (size.width / 2),
      y: 30 - (size.height / 2),
      child: ValueListenableBuilder(
        valueListenable: controller.isCharging,
        builder: (_, isCharging, __) {
          return isCharging
              ? theme!.getWidget(OnionThemeImage.icPowerCharge100)
              : ValueListenableBuilder(
                  valueListenable: controller.batteryLevel,
                  builder: (_, batteryLevel, __) {
                    final oti = switch (batteryLevel) {
                      0 => OnionThemeImage.power0Icon,
                      .25 => OnionThemeImage.power20Icon,
                      .5 => OnionThemeImage.power50Icon,
                      .75 => OnionThemeImage.power80Icon,
                      1 => OnionThemeImage.powerFullIcon,
                      _ => throw UnimplementedError(),
                    };
                    return theme!.getWidget(oti, listener: listener);
                  },
                );
        },
      ),
    );
  }
}
