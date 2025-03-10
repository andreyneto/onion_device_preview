import 'package:flutter/material.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/instances.dart';

class BgTitleComponent extends StatelessWidget {
  const BgTitleComponent({super.key});

  @override
  Widget build(BuildContext context) => theme!.getWidget(OnionThemeImage.bgTitle);
}
