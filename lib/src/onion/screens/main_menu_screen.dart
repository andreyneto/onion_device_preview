import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/onion/components/background_component.dart';
import 'package:onion_device_preview/src/onion/components/bg_title_component.dart';
import 'package:onion_device_preview/src/onion/components/div_line_h_component.dart';
import 'package:onion_device_preview/src/onion/components/footer_component.dart';
import 'package:onion_device_preview/src/onion/components/main_component.dart';
import 'package:onion_device_preview/src/onion/components/miyoo_topbar_component.dart';
import 'package:onion_device_preview/src/onion/components/network_component.dart';
import 'package:onion_device_preview/src/onion/screens/base_screen.dart';

import '../components/power_component.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseScreen(
      [
        BackgroundComponent(),
        BgTitleComponent(),
        MiyooTopBarComponent(),
        NetworkComponent(),
        DivLineHComponent(60),
        FooterComponent(),
        MainComponent(),
        PowerComponent(),
      ],
    );
  }
}
