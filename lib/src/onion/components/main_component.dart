import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onion_device_preview/onion_device_preview.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion/components/base_component.dart';
import 'package:onion_device_preview/src/onion/screens/base_screen.dart';
import 'package:onion_device_preview/src/onion_preview_controller.dart';

class MainGridItem {
  final OnionThemeImage focused;
  final OnionThemeImage normal;
  final OnionScreens screen;
  final String label;

  MainGridItem(this.focused, this.normal, this.screen, this.label);
}

class MainComponent extends StatefulWidget {
  const MainComponent({super.key});

  @override
  State<MainComponent> createState() => _MainComponentState();
}

class _MainComponentState extends State<MainComponent> implements KeysListener {
  bool hasExtras = controller.hasExtras.value;

  List<MainGridItem> get items => [
        if (hasExtras)
          MainGridItem(
            OnionThemeImage.icRecentF,
            OnionThemeImage.icRecentN,
            OnionScreens.roms,
            'Recents',
          ),
        MainGridItem(
          OnionThemeImage.icFavoriteF,
          OnionThemeImage.icFavoriteN,
          OnionScreens.roms,
          'Favorites',
        ),
        MainGridItem(
          OnionThemeImage.icGameF,
          OnionThemeImage.icGameN,
          OnionScreens.gameSystems,
          'Games',
        ),
        if (hasExtras)
          MainGridItem(
            OnionThemeImage.icRetroarchF,
            OnionThemeImage.icRetroarchN,
            OnionScreens.expert,
            'Expert',
          ),
        MainGridItem(
          OnionThemeImage.icAppF,
          OnionThemeImage.icAppN,
          OnionScreens.apps,
          'Apps',
        ),
        MainGridItem(
          OnionThemeImage.icSettingF,
          OnionThemeImage.icSettingN,
          OnionScreens.settings,
          'Settings',
        ),
      ];

  int scroll = 0;
  int current = 0;

  MainGridItem get selected => items[scroll + current];

  @override
  void initState() {
    super.initState();
    controller.addListener(this);
    controller.hasExtras.addListener(onExtrasChanged);
  }

  @override
  void dispose() {
    controller.removeListener(this);
    controller.hasExtras.removeListener(onExtrasChanged);
    super.dispose();
  }

  void onExtrasChanged() {
    setState(() {
      current = 0;
      scroll = 0;
      hasExtras = controller.hasExtras.value;
    });
  }

  List<Size> sizes = List.generate(4, (i) => Size(48, 48));

  @override
  Widget build(BuildContext context) {
    final dots = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      dots.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: theme!.getWidget(i == (scroll + current)
              ? OnionThemeImage.dotA
              : OnionThemeImage.dotN),
        ),
      );
    }

    return BaseScreen(
      [
        ...sizes
            .asMap()
            .keys
            .map(
              (i) => BaseComponent(
                child: Stack(
                  children: [
                    theme!.getWidget(
                        current == i
                            ? items[scroll + i].focused
                            : items[scroll + i].normal, listener: (info, __) {
                      final s = Size(
                        info.image.width.toDouble(),
                        info.image.height.toDouble(),
                      );
                      if (sizes[i] != s) {
                        setState(() => sizes[i] = s);
                      }
                    }),
                    Positioned.fill(
                      top: 120,
                      child: Center(
                        child: Text(
                          items[scroll + i].label,
                          style: current == i
                              ? theme?.config?.grid?.selectedStyle1x4
                              : theme?.config?.grid?.style1x4,
                        ),
                      ),
                    ),
                  ],
                ),
                x: (88 + 155 * i) - (sizes[i].width / 2),
                y: 230 - (sizes[i].height / 2),
              ),
            )
            .toList(),
        Positioned.fill(
          top: 312,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: dots,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void onA() => controller.goTo(selected.screen, selected.label);

  @override
  void onDown() {}

  @override
  void onLeft() => setState(() {
        if (current > 0)
          current -= 1;
        else if (scroll > 0)
          scroll -= 1;
        else {
          scroll = items.length - 4;
          current = 3;
        }
      });

  @override
  void onRight() => setState(() {
        if (current <= 2)
          current += 1;
        else if (scroll < items.length - 4)
          scroll += 1;
        else {
          current = 0;
          scroll = 0;
        }
      });

  @override
  void onUp() {}
}
