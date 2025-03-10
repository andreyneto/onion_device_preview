import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/onion/components/base_component.dart';

import '../../../onion_device_preview.dart';
import '../../instances.dart';

class FooterComponent extends StatelessWidget {
  const FooterComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final hideLabels = theme!.config!.hideLabels?.hints ?? false;

    final hasButtonA = true;
    final hasLabelA = !hideLabels;
    final hasButtonB = true;
    final hasLabelB = !hideLabels;

    final labelStyle = theme!.config!.hint?.style;
    return BaseComponent(
        child: SizedBox(
          height: 60,
          child: Stack(
            children: [
              theme!.getWidget(OnionThemeImage.tipsBarBg),
              Row(
                children: [
                  SizedBox(width: 20),
                  if (hasButtonA) theme!.getWidget(OnionThemeImage.iconA54),
                  if (hasButtonA) SizedBox(width: 5),
                  if (hasLabelA) Text('SELECT', style: labelStyle),
                  if (hasLabelA) SizedBox(width: 30),
                  if (hasButtonB) theme!.getWidget(OnionThemeImage.iconB54),
                  if (hasButtonB) SizedBox(width: 5),
                  if (hasLabelB) Text('BACK', style: labelStyle),
                ],
              ),
            ],
          ),
        ),
        x: 0,
        y: 420);
  }
}
