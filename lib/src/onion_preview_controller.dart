import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

enum OnionScreens {
  boot,
  mainMenu,
  charging,
  gameSwitcher,
  settings,
  apps,
  gameSystems,
  roms,
  contextMenu,
  popupNotification,
  promptMenu,
  shutDown,
  shutDownAndSave,
  loading,
  expert,
  gameInfo;
}

abstract class KeysListener {
  void onUp();
  void onDown();
  void onLeft();
  void onRight();
  void onA();
}

class OnionPreviewController {

  String currentLabel = '';

  ValueNotifier<List<OnionScreens>> currentScreen =
      ValueNotifier([OnionScreens.mainMenu]);

  ValueNotifier<bool> isPowerOn = ValueNotifier(true);

  ValueNotifier<bool> isCharging = ValueNotifier(false);

  ValueNotifier<bool> hasExtras = ValueNotifier(false);

  ValueNotifier<bool> isConnected = ValueNotifier(true);

  ValueNotifier<double> batteryLevel = ValueNotifier(1);

  ValueNotifier<int> wifiSignal = ValueNotifier(3);

  final List<KeysListener> _l = [];

  void addListener(KeysListener l) => _l.add(l);

  void removeListener(KeysListener l) => _l.remove(l);

  void action() => print('action');

  void keyPress(String k) {
    switch (k) {
      case 'Arrow Up':
        _l.forEach((element) => element.onUp());
      case 'Arrow Down':
        _l.forEach((element) => element.onDown());
      case 'Arrow Left':
        _l.forEach((element) => element.onLeft());
      case 'Arrow Right':
        _l.forEach((element) => element.onRight());
      case 'Z':
        controller.goBack();
      case 'X':
        _l.forEach((element) => element.onA());
      case 'A':
        action(); //Y
      case 'S':
        action(); //X
      case 'Shift Right':
        action();
      case 'Shift Left':
        action();
      case 'Enter':
        action();
      case 'Escape':
        action();
    }
  }

  void goTo(OnionScreens screen, String label) async {
    if(currentScreen.value.contains(OnionScreens.loading)) return;
    currentScreen.value = [...currentScreen.value, OnionScreens.loading];
    await Future.delayed(Duration(milliseconds: 1000));
    currentScreen.value..removeLast()..add(screen);
    currentLabel = label;
    currentScreen.notifyListeners();
  }

  void goBack() {
    if (currentScreen.value.length > 1 &&
        currentScreen.value.last != OnionScreens.loading)
      currentLabel = '';
      currentScreen.value.removeLast();
  }

  void powerHeld() {
    if (isPowerOn.value) {
      currentScreen.value = [OnionScreens.shutDownAndSave];
    }
  }

  void powerPressed() {
    if (isPowerOn.value) {
      currentScreen.value = [OnionScreens.shutDown];
    } else {
      isPowerOn.value = true;
      currentScreen.value = [OnionScreens.boot];
    }
  }

  Future<void> fetchConfig() async {
    try {
      final baseUrl = (theme as NetworkOnionTheme).baseUrl;
      final name = (theme as NetworkOnionTheme).name;
      final url = '$baseUrl/themes/$name/config.json';

      final response = await get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final config = OnionThemeConfig.fromJson(json);
        theme?.config = config;
      } else {
        log(response.body);
      }
    } catch (e) {
      log(e.toString());
    }
  }

  List<dynamic> getRomsList() {
    return [];
  }

  Map<String, String> getGameSystemsList() {
    return {
      'Atari': 'atari.png',
      'Gameboy': 'gb.png',
      'Genesis': 'md.png',
      'NES': 'fc.png',
      'Playstation': 'ps.png',
      'SNES': 'sfc.png',
    };
  }
}
