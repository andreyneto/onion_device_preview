import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/onion_preview.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class MiyooDevice extends StatefulWidget {
  final OnionTheme? theme;
  final bool precacheImages;

  MiyooDevice(this.theme, {super.key, this.precacheImages = true});

  @override
  State<MiyooDevice> createState() => _MiyooDeviceState();
}

class _MiyooDeviceState extends State<MiyooDevice> {
  String lastKey = '';

  Widget buildScreen() => Positioned(
      left: 12,
      right: 12,
      top: 10,
      bottom: 480,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.black87, borderRadius: BorderRadius.circular(12)),
      ));

  Widget buildPreview() => Positioned(
        left: 27,
        top: 24,
        right: 27,
        child: OnionPreview(precacheImages: widget.precacheImages),
      );

  Widget buildBody(ColorScheme colors) => Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
      );

  Widget buildActionButton(ColorScheme colors, bool pressed) => Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
            color: pressed ? colors.tertiary : colors.primary,
            borderRadius: BorderRadius.circular(46)),
      );

  Widget buildB(colors) {
    final pressed = lastKey == 'Z';
    return Positioned(
      top: 774,
      left: 478,
      child: InkWell(
        onTapDown: (_) => setState(() {
          lastKey = 'Z';
        }),
        onTapUp: (_) => setState(() {
          lastKey = '';
        }),
        child: buildActionButton(colors, pressed),
      ),
    );
  }

  Widget buildA(colors) {
    final pressed = lastKey == 'X';
    return Positioned(
      top: 683,
      left: 569,
      child: InkWell(
        onTapDown: (_) => setState(() {
          lastKey = 'X';
        }),
        onTapUp: (_) => setState(() {
          lastKey = '';
        }),
        child: buildActionButton(colors, pressed),
      ),
    );
  }

  Widget buildY(colors) {
    final pressed = lastKey == 'A';
    return Positioned(
      top: 683,
      left: 387,
      child: InkWell(
        onTapDown: (_) => setState(() {
          lastKey = 'A';
        }),
        onTapUp: (_) => setState(() {
          lastKey = '';
        }),
        child: buildActionButton(colors, pressed),
      ),
    );
  }

  Widget buildX(colors) {
    final pressed = lastKey == 'S';
    return Positioned(
      top: 592,
      left: 478,
      child: InkWell(
        onTapDown: (_) => setState(() {
          lastKey = 'S';
        }),
        onTapUp: (_) => setState(() {
          lastKey = '';
        }),
        child: buildActionButton(colors, pressed),
      ),
    );
  }

  Widget buildDpad(ColorScheme colors) {
    return Positioned(
      top: 610,
      left: 45,
      child: SizedBox.square(
        dimension: 235,
        child: Stack(
          children: [
            Positioned(
              left: 74,
              top: 74,
              child: Container(
                width: 87,
                height: 87,
                color: colors.secondary,
              ),
            ),
            Positioned(
              left: 75,
              child: InkWell(
                onTapDown: (_) => setState(() {
                  lastKey = 'Arrow Up';
                }),
                onTapUp: (_) => setState(() {
                  lastKey = '';
                }),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    width: 85,
                    height: 75,
                    color: lastKey == 'Arrow Up'
                        ? colors.tertiary
                        : colors.secondary,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 75,
              bottom: 0,
              child: InkWell(
                onTapDown: (_) => setState(() {
                  lastKey = 'Arrow Down';
                }),
                onTapUp: (_) => setState(() {
                  lastKey = '';
                }),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: Container(
                    width: 85,
                    height: 75,
                    color: lastKey == 'Arrow Down'
                        ? colors.tertiary
                        : colors.secondary,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 75,
              right: 0,
              child: InkWell(
                onTapDown: (_) => setState(() {
                  lastKey = 'Arrow Right';
                }),
                onTapUp: (_) => setState(() {
                  lastKey = '';
                }),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(16),
                  ),
                  child: Container(
                    width: 75,
                    height: 85,
                    color: lastKey == 'Arrow Right'
                        ? colors.tertiary
                        : colors.secondary,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 75,
              child: InkWell(
                onTapDown: (_) => setState(() {
                  lastKey = 'Arrow Left';
                }),
                onTapUp: (_) => setState(() {
                  lastKey = '';
                }),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: Container(
                    width: 75,
                    height: 85,
                    color: lastKey == 'Arrow Left'
                        ? colors.tertiary
                        : colors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenu(ColorScheme colors) {
    final pressed = lastKey == 'Escape';
    return Positioned(
      left: 0,
      right: 0,
      bottom: 352,
      child: InkWell(
        onTapDown: (_) => setState(() {
          lastKey = 'Escape';
        }),
        onTapUp: (_) => setState(() {
          lastKey = '';
        }),
        child: Center(
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
                color: pressed ? colors.tertiary : colors.secondary,
                borderRadius: BorderRadius.circular(46)),
          ),
        ),
      ),
    );
  }

  Widget buildStart(colors) {
    final pressed = lastKey == 'Enter';
    return Positioned(
      bottom: 50,
      left: 310,
      child: InkWell(
          onTapDown: (_) => setState(() {
                lastKey = 'Enter';
              }),
          onTapUp: (_) => setState(() {
                lastKey = '';
              }),
          child: buildPill(colors, pressed)),
    );
  }

  Widget buildSelect(colors) {
    final pressed = lastKey.contains('Shift');
    return Positioned(
      bottom: 50,
      left: 200,
      child: InkWell(
          onTapDown: (_) => setState(() {
                lastKey = 'Shift Left';
              }),
          onTapUp: (_) => setState(() {
                lastKey = '';
              }),
          child: buildPill(colors, pressed)),
    );
  }

  Widget buildPill(ColorScheme colors, bool pressed) {
    return Transform.rotate(
      angle: -pi / 5,
      child: Container(
        width: 100,
        height: 30,
        decoration: BoxDecoration(
            color: pressed ? colors.tertiary : colors.secondary,
            borderRadius: BorderRadius.circular(46)),
      ),
    );
  }

  Widget buildSound() {
    return Positioned(
      top: 870,
      right: 50,
      child: Transform.rotate(
        angle: pi / 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.filled(
            4,
            Container(
              width: 80,
              height: 10,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(46)),
            ),
          )
              .expand((c) => [
                    c,
                    const SizedBox(
                      height: 20,
                    )
                  ])
              .toList()
            ..removeLast(),
        ),
      ),
    );
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyRepeatEvent) return false;
    if (event is KeyUpEvent) {
      setState(() {
        lastKey = '';
      });
      return true;
    }

    final keys = [
      'Arrow Up',
      'Arrow Down',
      'Arrow Left',
      'Arrow Right',
      'Z', //B
      'X', //A
      'A', //Y
      'S', //X
      'Shift Right',
      'Shift Left',
      'Enter',
      'Escape',
    ];

    if (!keys.contains(event.logicalKey.keyLabel)) return false;

    setState(() {
      lastKey = event.logicalKey.keyLabel;
    });

    return true;
  }

  Widget buildDeviceMenu() {
    final items = ['wifi', 'battery', 'extra'];
    final icons = {
      'wifi': Icons.wifi_rounded,
      'battery': Icons.battery_charging_full_rounded,
      'extra': null,
    };
    final labels = {
      'wifi': 'Wifi',
      'battery': 'Battery',
      'extra': 'Extras',
    };
    final toggles = {
      'wifi': ValueListenableBuilder(
        valueListenable: controller.isConnected,
        builder: (_, isConnected, __) => Switch(
          value: isConnected,
          onChanged: (_) => controller.isConnected.value = !isConnected,
        ),
      ),
      'battery': ValueListenableBuilder(
        valueListenable: controller.isCharging,
        builder: (_, isCharging, __) => Switch(
          value: isCharging,
          onChanged: (_) => controller.isCharging.value = !isCharging,
        ),
      ),
      'extra': ValueListenableBuilder(
        valueListenable: controller.hasExtras,
        builder: (_, hasExtras, __) => Switch(
          value: hasExtras,
          onChanged: (_) => controller.hasExtras.value = !hasExtras,
        ),
      ),
    };
    final actions = {
      'wifi': ValueListenableBuilder(
        valueListenable: controller.wifiSignal,
        builder: (_, wifiSignal, __) => SliderTheme(
          data: SliderThemeData(overlayShape: SliderComponentShape.noThumb),
          child: Slider(
            min: 1,
            max: 4,
            divisions: 3,
            onChanged: (v) => controller.wifiSignal.value = v.toInt(),
            value: wifiSignal.toDouble(),
          ),
        ),
      ),
      'battery': ValueListenableBuilder(
        valueListenable: controller.batteryLevel,
        builder: (_, batteryLevel, __) => SliderTheme(
          data: SliderThemeData(overlayShape: SliderComponentShape.noThumb),
          child: Slider(
            divisions: 4,
            onChanged: (v) => controller.batteryLevel.value = v,
            value: batteryLevel,
          ),
        ),
      ),
      'extra': Text('Show recent and expert'),
    };
    return ListView.builder(
      shrinkWrap: false,
      itemCount: items.length,
      itemBuilder: (_, i) => ListTile(
        isThreeLine: true,
        title: Text(labels[items[i]] ?? ''),
        subtitle: actions[items[i]],
        leading: Icon(icons[items[i]]),
        trailing: toggles[items[i]],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.keyboard.addHandler(_onKey);
    theme = widget.theme;
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (lastKey.isNotEmpty) controller.keyPress(lastKey);
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.tonalIcon(
            onPressed: controller.powerPressed,
            onLongPress: controller.powerHeld,
            icon: Icon(Icons.power_settings_new_rounded),
            label: ValueListenableBuilder(
              valueListenable: controller.isPowerOn,
              builder: (_, isPowerOn, __) => Text(' •',
                  style: TextStyle(
                      color: isPowerOn ? Colors.greenAccent : null,
                      fontSize: 36)),
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.70,
          ),
          child: FittedBox(
            child: SizedBox(
              width: 694,
              height: 999,
              child: Stack(
                children: [
                  buildBody(colors),
                  buildScreen(),
                  buildDpad(colors),
                  buildMenu(colors),
                  buildStart(colors),
                  buildSelect(colors),
                  buildA(colors),
                  buildB(colors),
                  buildX(colors),
                  buildY(colors),
                  buildPreview(),
                  buildSound(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            margin: EdgeInsets.all(16.0),
            clipBehavior: Clip.hardEdge,
            child: buildDeviceMenu(),
          ),
        ),
      ],
    );
  }
}
