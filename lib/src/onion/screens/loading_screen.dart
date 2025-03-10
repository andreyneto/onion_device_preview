import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/components/background_component.dart';
import 'package:onion_device_preview/src/onion/components/base_component.dart';
import 'package:onion_device_preview/src/onion/screens/base_screen.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Size size = Size.zero;

  int progress = 0;

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
  void initState() {
    super.initState();
    update();
  }

  void update() async {
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      progress = (progress + 1) % 4;
    });
    update();
  }

  @override
  Widget build(BuildContext context) => BaseScreen(
        [
          BackgroundComponent(),
          Positioned.fill(
            top: 160,
            child: Text(
              'LOADING',
              textAlign: TextAlign.center,
              style: theme?.config?.title?.style,
            ),
          ),
          if (progress >= 1)
            BaseComponent(
              x: 320 - 32 - (size.width / 2),
              y: 225 - (size.height / 2),
              child: theme!.getWidget(OnionThemeImage.progressDot),
            ),
          if (progress >= 2)
            BaseComponent(
              x: 320 - (size.width / 2),
              y: 225 - (size.height / 2),
              child: theme!.getWidget(OnionThemeImage.progressDot),
            ),
          if (progress >= 3)
            BaseComponent(
              x: 320 + 32 - (size.width / 2),
              y: 225 - (size.height / 2),
              child: theme!.getWidget(OnionThemeImage.progressDot),
            ),
        ],
      );
}
