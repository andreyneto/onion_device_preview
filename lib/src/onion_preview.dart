import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/screens/boot_screen.dart';
import 'package:onion_device_preview/src/onion/screens/charging_screen.dart';
import 'package:onion_device_preview/src/onion/screens/loading_screen.dart';
import 'package:onion_device_preview/src/onion/screens/main_menu_screen.dart';
import 'package:onion_device_preview/src/onion/screens/roms_screen.dart';
import 'package:onion_device_preview/src/onion/screens/shutdown_screen.dart';
import 'package:onion_device_preview/src/onion_preview_controller.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class OnionPreview extends StatefulWidget {
  final bool precacheImages;
  const OnionPreview({super.key, required this.precacheImages});

  @override
  State<OnionPreview> createState() => _OnionPreviewState();
}

class _OnionPreviewState extends State<OnionPreview> {
  bool isFetching = false;
  double? fetchProgress;
  String? preload;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildOffState() => ValueListenableBuilder(
      valueListenable: controller.isCharging,
      builder: (_, isCharging, __) => isCharging
          ? ChargingScreen()
          : Center(
              child: Text(
              'device off',
              style: TextStyle(color: Colors.white),
            )));

  Widget _buildPowerState() => ValueListenableBuilder(
      valueListenable: controller.isPowerOn,
      builder: (_, isPowerOn, __) =>
          isPowerOn ? _buildOnState() : _buildOffState());

  Widget _buildOnState() => ValueListenableBuilder(
        valueListenable: controller.currentScreen,
        builder: (_, currentScreen, __) {
          print('screen: ' + currentScreen.toString());
          return switch (currentScreen.last) {
            OnionScreens.boot => BootScreen(),
            OnionScreens.mainMenu => MainMenuScreen(),
            OnionScreens.shutDown => ShutdownScreen(),
            OnionScreens.charging => ChargingScreen(),
            OnionScreens.gameSwitcher => throw UnimplementedError(),
            OnionScreens.settings => throw UnimplementedError(),
            OnionScreens.apps => throw UnimplementedError(),
            OnionScreens.gameSystems => throw UnimplementedError(),
            OnionScreens.roms => RomsScreen(),
            OnionScreens.contextMenu => throw UnimplementedError(),
            OnionScreens.popupNotification => throw UnimplementedError(),
            OnionScreens.promptMenu => throw UnimplementedError(),
            OnionScreens.shutDownAndSave => ShutdownScreen(save: true),
            OnionScreens.loading => LoadingScreen(),
            OnionScreens.expert => throw UnimplementedError(),
            OnionScreens.gameInfo => throw UnimplementedError(),
          };
        },
      );

  @override
  void didChangeDependencies() {
    if (theme != null) precache();
    super.didChangeDependencies();
  }

  Future<void> precache() async {
    setState(() => isFetching = true);
    setState(() => preload = 'Fetching config');
    await controller.fetchConfig();
    if (widget.precacheImages) {
      final total = OnionThemeImage.values.length;
      int i = 0;
      for (var element in OnionThemeImage.values) {
        setState(() => fetchProgress = i++ / total);
        setState(() => preload = 'Preloading images\n${element.name}');
        await precacheImage(theme!.getWidget(element).image, context);
        await Future.delayed(Duration(milliseconds: 10));
      }
    } else {
      for (var i = 0; i <= 150; i++) {
        setState(() => fetchProgress = i++ / 150);
        await Future.delayed(Duration(milliseconds: 10));
      }
    }
    setState(() => isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: 640,
        height: 480,
        child: theme == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    Text(
                      'No theme selected',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : (isFetching
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 24,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white.withOpacity(0.36),
                              ),
                              CircularProgressIndicator(
                                color: Colors.white,
                                value: fetchProgress,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\n${((fetchProgress ?? 0) * 100).ceil()}%\n$preload',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _buildPowerState()),
      ),
    );
  }
}
