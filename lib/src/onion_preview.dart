import 'package:flutter/material.dart';
import 'package:onion_device_preview/src/onion_preview_controller.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class OnionPreview extends StatefulWidget {
  final OnionPreviewController controller;
  final OnionTheme? theme;

  const OnionPreview(this.controller, this.theme, {super.key});

  @override
  State<OnionPreview> createState() => _OnionPreviewState();
}

class _OnionPreviewState extends State<OnionPreview> {
  int get focused => widget.controller.focusedIndex.value;

  @override
  void initState() {
    super.initState();
    widget.controller.focusedIndex.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return FittedBox(
      child: SizedBox(
        width: 640,
        height: 480,
        child: theme == null
            ? SizedBox.shrink()
            : Stack(
                children: [
                  theme.background,
                  Positioned(top: 0, child: theme.bgTitle),
                  // Positioned(
                  //     top: 6, right: 36, child: ThemeFile.powerFullIcon.widget),
                  // Positioned(
                  //     top: 6, right: 60, child: ThemeFile.iconWifiSignal04.widget),
                  // Positioned(bottom: 0, child: ThemeFile.tipsBarBg.widget),
                  Positioned(
                    bottom: 76,
                    right: 0,
                    left: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          (focused == 0 ? theme.dotA : theme.dotN),
                          (focused == 1 ? theme.dotA : theme.dotN),
                          (focused == 2 ? theme.dotA : theme.dotN),
                          (focused == 3 ? theme.dotA : theme.dotN),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 90,
                    right: 0,
                    left: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          (focused == 0
                              ? theme.icFavoriteF
                              : theme.icFavoriteN),
                          (focused == 1 ? theme.icGameF : theme.icGameN),
                          (focused == 2 ? theme.icAppF : theme.icAppN),
                          (focused == 3 ? theme.icSettingF : theme.icSettingN),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}