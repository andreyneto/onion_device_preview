import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/components/base_component.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class NetworkComponent extends StatefulWidget {
  const NetworkComponent({super.key});

  @override
  State<NetworkComponent> createState() => _PowerComponentState();
}

class _PowerComponentState extends State<NetworkComponent> {
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
      x: 512 - (size.width / 2),
      y: 30 - (size.height / 2),
      child: ValueListenableBuilder(
        valueListenable: controller.isConnected,
        builder: (_, isConnected, __) {
          return !isConnected
              ? SizedBox.shrink()
              : ValueListenableBuilder(
                  valueListenable: controller.wifiSignal,
                  builder: (_, wifiSignal, __) {
                    final oti = switch (wifiSignal) {
                      1 => OnionThemeImage.iconWifiSignal01,
                      2 => OnionThemeImage.iconWifiSignal02,
                      3 => OnionThemeImage.iconWifiSignal03,
                      4 => OnionThemeImage.iconWifiSignal04,
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
