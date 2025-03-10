import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/components/base_component.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class MiyooTopBarComponent extends StatefulWidget {
  const MiyooTopBarComponent({super.key});

  @override
  State<MiyooTopBarComponent> createState() => _PowerComponentState();
}

class _PowerComponentState extends State<MiyooTopBarComponent> {
  Size size = Size.square(0);

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
      x: 20,
      y: 30 - (size.height / 2),
      child: theme!.getWidget(OnionThemeImage.miyooTopbar, listener: listener),
    );
  }
}
