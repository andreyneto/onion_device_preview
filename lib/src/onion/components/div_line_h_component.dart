import 'package:flutter/material.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/components/base_component.dart';

class DivLineHComponent extends StatelessWidget {
  final double verticalPosition;
  const DivLineHComponent(this.verticalPosition, {super.key});

  @override
  Widget build(BuildContext context) => BaseComponent(
        x: 0,
        y: verticalPosition,
        child: theme!.getWidget(OnionThemeImage.divLineH),
      );
}
