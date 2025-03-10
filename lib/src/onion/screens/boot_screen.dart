import 'package:flutter/widgets.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion_preview_controller.dart';
import 'package:onion_device_preview/src/onion_theme.dart';
import 'package:onion_device_preview/src/utils.dart';

class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    delayed(() => controller.currentScreen.value = [OnionScreens.mainMenu]);
    return theme!.getWidget(OnionThemeImage.bootScreen);
  }
}
