import 'package:flutter/widgets.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/screens/base_screen.dart';
import 'package:onion_device_preview/src/onion_preview_controller.dart';
import 'package:onion_device_preview/src/onion_theme.dart';
import 'package:onion_device_preview/src/utils.dart';

class ShutdownScreen extends StatelessWidget {
  final bool save;
  const ShutdownScreen({super.key, this.save = false});

  @override
  Widget build(BuildContext context) {
    delayed(() => controller.isPowerOn.value = false);
    return BaseScreen([
      if(save) theme!.getWidget(OnionThemeImage.screenOffSave),
      if(!save) theme!.getWidget(OnionThemeImage.screenOff),
      ]
    );
  }
}
