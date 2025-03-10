import 'package:flutter/material.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
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
    final list = controller.getRomsList();
    return BaseScreen( [

      BackgroundComponent(),
      BgTitleComponent(),
      FooterComponent(),
      DivLineHComponent(60),
      // 09 bg-list-s
      // 10 icon-folder
      // 11 icon-game
      // 12 icon-TF
      // 13 preview-bg / preview image/icon
      // 14 ic-favorite-mark
      if(list.isEmpty) Center(child: theme!.getWidget(OnionThemeImage.empty),),
      PowerComponent(),
    ]);
  }
}
