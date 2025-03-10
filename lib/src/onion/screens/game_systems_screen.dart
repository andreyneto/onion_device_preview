import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/components/background_component.dart';
import 'package:onion_device_preview/src/onion/components/bg_title_component.dart';
import 'package:onion_device_preview/src/onion/components/div_line_h_component.dart';
import 'package:onion_device_preview/src/onion/components/footer_component.dart';
import 'package:onion_device_preview/src/onion/components/power_component.dart';
import 'package:onion_device_preview/src/onion/screens/base_screen.dart';

class RomsScreen extends StatelessWidget {
  const RomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = controller.getGameSystemsList();
    return BaseScreen([
      BackgroundComponent(),
      BgTitleComponent(),
      DivLineHComponent(60),
      FooterComponent(),
      //Grid()
      PowerComponent(),
    ]);
  }
}

// Game Systems
// 07 bg-game-item-f
// 08 bg-game-item-n