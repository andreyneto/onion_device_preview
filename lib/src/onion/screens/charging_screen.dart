import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion_theme.dart';
import 'package:onion_device_preview/src/utils.dart';

class ChargingScreen extends StatefulWidget {
  const ChargingScreen({super.key});

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {

  var current = OnionThemeImage.chargingState0;
  final list = [
    OnionThemeImage.chargingState0,
    OnionThemeImage.chargingState1,
    OnionThemeImage.chargingState2,
    OnionThemeImage.chargingState3,
    OnionThemeImage.chargingState4,
    OnionThemeImage.chargingState5,
    OnionThemeImage.chargingState6,
    OnionThemeImage.chargingState7,
    OnionThemeImage.chargingState8,
    OnionThemeImage.chargingState9,
    OnionThemeImage.chargingState10,
    OnionThemeImage.chargingState11,
    OnionThemeImage.chargingState12,
    OnionThemeImage.chargingState13,
    OnionThemeImage.chargingState14,
    OnionThemeImage.chargingState15,
    OnionThemeImage.chargingState16,
    OnionThemeImage.chargingState17,
    OnionThemeImage.chargingState18,
    OnionThemeImage.chargingState19,
    OnionThemeImage.chargingState20,
    OnionThemeImage.chargingState21,
    OnionThemeImage.chargingState22,
    OnionThemeImage.chargingState23,
  ];
  int frameDelay = 0;

  @override
  void initState() {
    super.initState();
    final value = 80;
    frameDelay = (value >= 10000 ? value / 1000 : value).toInt();
    next();
  }

  void next() {
    delayed(() => setState(() {
      try {
        final i = list.indexOf(current);
        current = list[i + 1];
      } catch (_) {
        current = list.first;
      }
      next();
    }), t: frameDelay);
  }

  @override
  Widget build(BuildContext context) {
    return theme!.getWidget(current);
  }
}
