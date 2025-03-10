import 'package:flutter/widgets.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/instances.dart';

class BackgroundComponent extends StatelessWidget {
  const BackgroundComponent({super.key});

  @override
  Widget build(BuildContext context) => RotatedBox(
      quarterTurns: 2,
      child: theme!.getWidget(OnionThemeImage.background),
    );
}
