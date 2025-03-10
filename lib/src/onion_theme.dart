import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:onion_device_preview/src/instances.dart';
import 'package:onion_device_preview/src/utils.dart';

enum OnionThemeImage {
  screenOff,
  screenOffSave,
  bootScreen,
  chargingState0,
  chargingState1,
  chargingState2,
  chargingState3,
  chargingState4,
  chargingState5,
  chargingState6,
  chargingState7,
  chargingState8,
  chargingState9,
  chargingState10,
  chargingState11,
  chargingState12,
  chargingState13,
  chargingState14,
  chargingState15,
  chargingState16,
  chargingState17,
  chargingState18,
  chargingState19,
  chargingState20,
  chargingState21,
  chargingState22,
  chargingState23,
  gsBottomBart,
  gsTopBar,
  lowBat,
  lum0,
  lum1,
  lum2,
  lum3,
  lum4,
  lum5,
  lum6,
  lum7,
  lum8,
  lum9,
  lum10,
  toggleOff,
  toggleOn,
  empty,
  background,
  bgButtonF,
  bgGameItemF,
  bgGameItemN,
  bgIoTesting,
  bgKeySettingF,
  bgKeySetting,
  bgListL,
  bgListS,
  bgPopMenu1,
  bgPopMenu2,
  bgPopMenu3,
  bgPopMenu4,
  bgRaListItem,
  bgTitle,
  color,
  divLineH,
  divLineV01,
  dotA,
  dotN,
  fixit,
  headphoneIcon,
  icMENUA,
  icMENU,
  icAppF,
  icAppN,
  icFavoriteF,
  icFavoriteMark,
  icFavoriteN,
  icGameF,
  icGameN,
  icPowerCharge100,
  icRecentF,
  icRecentN,
  icRetroarchF,
  icRetroarchN,
  icSettingF,
  icSettingN,
  iconA54,
  iconB54,
  iconShutdown,
  iconTF,
  iconBrightness48,
  iconDeviceInfo48,
  iconFactoryReset48,
  iconFolder,
  iconGame,
  iconKeySetting48,
  iconLanguage48,
  iconLeftArrow24,
  iconRightArrow24,
  iconSettingWifi,
  iconWifiConnected,
  iconWifiLocked,
  iconWifiSignal01,
  iconWifiSignal02,
  iconWifiSignal03,
  iconWifiSignal04,
  listNum,
  miyooTopbar,
  numBg,
  popBg,
  power0Icon,
  power20Icon,
  power50Icon,
  power80Icon,
  powerFullIcon,
  previewBg,
  progressDot,
  soundIcon,
  thumbDefault,
  tipsBarBg,
  preview;
}

abstract class OnionTheme {
  OnionThemeConfig? config;

  Image getWidget(OnionThemeImage image, {ImageListener? listener});
}

class NetworkOnionTheme extends OnionTheme {
  final String baseUrl =
      'https://raw.githubusercontent.com/OnionUI/Themes/main/';
  final String name;

  NetworkOnionTheme({required this.name});

  @override
  Image getWidget(OnionThemeImage image, {ImageListener? listener}) {
    if (image == OnionThemeImage.preview)
      return Image.network('$baseUrl/themes/$name/preview.png',
          width: 640, height: 480, fit: BoxFit.cover);
    final imagePath = switch (image) {
      OnionThemeImage.screenOff => '/skin/extra/Screen_Off.png',
      OnionThemeImage.screenOffSave => '/skin/extra/Screen_Off_Save.png',
      OnionThemeImage.bootScreen => '/skin/extra/bootScreen.png',
      OnionThemeImage.chargingState0 => '/skin/extra/chargingState0.png',
      OnionThemeImage.chargingState1 => '/skin/extra/chargingState1.png',
      OnionThemeImage.chargingState2 => '/skin/extra/chargingState2.png',
      OnionThemeImage.chargingState3 => '/skin/extra/chargingState3.png',
      OnionThemeImage.chargingState4 => '/skin/extra/chargingState4.png',
      OnionThemeImage.chargingState5 => '/skin/extra/chargingState5.png',
      OnionThemeImage.chargingState6 => '/skin/extra/chargingState6.png',
      OnionThemeImage.chargingState7 => '/skin/extra/chargingState7.png',
      OnionThemeImage.chargingState8 => '/skin/extra/chargingState8.png',
      OnionThemeImage.chargingState9 => '/skin/extra/chargingState9.png',
      OnionThemeImage.chargingState10 => '/skin/extra/chargingState10.png',
      OnionThemeImage.chargingState11 => '/skin/extra/chargingState11.png',
      OnionThemeImage.chargingState12 => '/skin/extra/chargingState12.png',
      OnionThemeImage.chargingState13 => '/skin/extra/chargingState13.png',
      OnionThemeImage.chargingState14 => '/skin/extra/chargingState14.png',
      OnionThemeImage.chargingState15 => '/skin/extra/chargingState15.png',
      OnionThemeImage.chargingState16 => '/skin/extra/chargingState16.png',
      OnionThemeImage.chargingState17 => '/skin/extra/chargingState17.png',
      OnionThemeImage.chargingState18 => '/skin/extra/chargingState18.png',
      OnionThemeImage.chargingState19 => '/skin/extra/chargingState19.png',
      OnionThemeImage.chargingState20 => '/skin/extra/chargingState20.png',
      OnionThemeImage.chargingState21 => '/skin/extra/chargingState21.png',
      OnionThemeImage.chargingState22 => '/skin/extra/chargingState22.png',
      OnionThemeImage.chargingState23 => '/skin/extra/chargingState23.png',
      OnionThemeImage.gsBottomBart => '/skin/extra/gs-bottom-bar.png',
      OnionThemeImage.gsTopBar => '/skin/extra/gs-top-bar.png',
      OnionThemeImage.lowBat => '/skin/extra/lowBat.png',
      OnionThemeImage.lum0 => '/skin/extra/lum0.png',
      OnionThemeImage.lum1 => '/skin/extra/lum1.png',
      OnionThemeImage.lum2 => '/skin/extra/lum2.png',
      OnionThemeImage.lum3 => '/skin/extra/lum3.png',
      OnionThemeImage.lum4 => '/skin/extra/lum4.png',
      OnionThemeImage.lum5 => '/skin/extra/lum5.png',
      OnionThemeImage.lum6 => '/skin/extra/lum6.png',
      OnionThemeImage.lum7 => '/skin/extra/lum7.png',
      OnionThemeImage.lum8 => '/skin/extra/lum8.png',
      OnionThemeImage.lum9 => '/skin/extra/lum9.png',
      OnionThemeImage.lum10 => '/skin/extra/lum10.png',
      OnionThemeImage.toggleOff => '/skin/extra/toggle-off.png',
      OnionThemeImage.toggleOn => '/skin/extra/toggle-on.png',
      OnionThemeImage.empty => '/skin/Empty.png',
      OnionThemeImage.background => '/skin/background.png',
      OnionThemeImage.bgButtonF => '/skin/bg-button-f.png',
      OnionThemeImage.bgGameItemF => '/skin/bg-game-item-f.png',
      OnionThemeImage.bgGameItemN => '/skin/bg-game-item-n.png',
      OnionThemeImage.bgIoTesting => '/skin/bg-io-testing.png',
      OnionThemeImage.bgKeySettingF => '/skin/bg-keysetting-f.png',
      OnionThemeImage.bgKeySetting => '/skin/bg-keysetting.png',
      OnionThemeImage.bgListL => '/skin/bg-list-l.png',
      OnionThemeImage.bgListS => '/skin/bg-list-s.png',
      OnionThemeImage.bgPopMenu1 => '/skin/bg-pop-menu-1.png',
      OnionThemeImage.bgPopMenu2 => '/skin/bg-pop-menu-2.png',
      OnionThemeImage.bgPopMenu3 => '/skin/bg-pop-menu-3.png',
      OnionThemeImage.bgPopMenu4 => '/skin/bg-pop-menu-4.png',
      OnionThemeImage.bgRaListItem => '/skin/bg-ra-list-item.png',
      OnionThemeImage.bgTitle => '/skin/bg-title.png',
      OnionThemeImage.color => '/skin/color.png',
      OnionThemeImage.divLineH => '/skin/div-line-h.png',
      OnionThemeImage.divLineV01 => '/skin/div-line-v-01.png',
      OnionThemeImage.dotA => '/skin/dot-a.png',
      OnionThemeImage.dotN => '/skin/dot-n.png',
      OnionThemeImage.fixit => '/skin/fixit.png',
      OnionThemeImage.headphoneIcon => '/skin/headphone-icon.png',
      OnionThemeImage.icMENUA => '/skin/ic-MENU+A.png',
      OnionThemeImage.icMENU => '/skin/ic-MENU.png',
      OnionThemeImage.icAppF => '/skin/ic-app-f.png',
      OnionThemeImage.icAppN => '/skin/ic-app-n.png',
      OnionThemeImage.icFavoriteF => '/skin/ic-favorite-f.png',
      OnionThemeImage.icFavoriteMark => '/skin/ic-favorite-mark.png',
      OnionThemeImage.icFavoriteN => '/skin/ic-favorite-n.png',
      OnionThemeImage.icGameF => '/skin/ic-game-f.png',
      OnionThemeImage.icGameN => '/skin/ic-game-n.png',
      OnionThemeImage.icPowerCharge100 => '/skin/ic-power-charge-100%.png',
      OnionThemeImage.icRecentF => '/skin/ic-recent-f.png',
      OnionThemeImage.icRecentN => '/skin/ic-recent-n.png',
      OnionThemeImage.icRetroarchF => '/skin/ic-retroarch-f.png',
      OnionThemeImage.icRetroarchN => '/skin/ic-retroarch-n.png',
      OnionThemeImage.icSettingF => '/skin/ic-setting-f.png',
      OnionThemeImage.icSettingN => '/skin/ic-setting-n.png',
      OnionThemeImage.iconA54 => '/skin/icon-A-54.png',
      OnionThemeImage.iconB54 => '/skin/icon-B-54.png',
      OnionThemeImage.iconShutdown => '/skin/icon-Shutdown.png',
      OnionThemeImage.iconTF => '/skin/icon-TF.png',
      OnionThemeImage.iconBrightness48 => '/skin/icon-brightness-48.png',
      OnionThemeImage.iconDeviceInfo48 => '/skin/icon-device-info-48.png',
      OnionThemeImage.iconFactoryReset48 => '/skin/icon-factory-reset-48.png',
      OnionThemeImage.iconFolder => '/skin/icon-folder.png',
      OnionThemeImage.iconGame => '/skin/icon-game.png',
      OnionThemeImage.iconKeySetting48 => '/skin/icon-key-setting-48.png',
      OnionThemeImage.iconLanguage48 => '/skin/icon-language-48.png',
      OnionThemeImage.iconLeftArrow24 => '/skin/icon-left-arrow-24.png',
      OnionThemeImage.iconRightArrow24 => '/skin/icon-right-arrow-24.png',
      OnionThemeImage.iconSettingWifi => '/skin/icon-setting-wifi.png',
      OnionThemeImage.iconWifiConnected => '/skin/icon-wifi-connected.png',
      OnionThemeImage.iconWifiLocked => '/skin/icon-wifi-locked.png',
      OnionThemeImage.iconWifiSignal01 => '/skin/icon-wifi-signal-01.png',
      OnionThemeImage.iconWifiSignal02 => '/skin/icon-wifi-signal-02.png',
      OnionThemeImage.iconWifiSignal03 => '/skin/icon-wifi-signal-03.png',
      OnionThemeImage.iconWifiSignal04 => '/skin/icon-wifi-signal-04.png',
      OnionThemeImage.listNum => '/skin/list-num.png',
      OnionThemeImage.miyooTopbar => '/skin/miyoo-topbar.png',
      OnionThemeImage.numBg => '/skin/num-bg.png',
      OnionThemeImage.popBg => '/skin/pop-bg.png',
      OnionThemeImage.power0Icon => '/skin/power-0%-icon.png',
      OnionThemeImage.power20Icon => '/skin/power-20%-icon.png',
      OnionThemeImage.power50Icon => '/skin/power-50%-icon.png',
      OnionThemeImage.power80Icon => '/skin/power-80%-icon.png',
      OnionThemeImage.powerFullIcon => '/skin/power-full-icon.png',
      OnionThemeImage.previewBg => '/skin/preview-bg.png',
      OnionThemeImage.progressDot => '/skin/progress-dot.png',
      OnionThemeImage.soundIcon => '/skin/sound-icon.png',
      OnionThemeImage.thumbDefault => '/skin/thumb-default.png',
      OnionThemeImage.tipsBarBg => '/skin/tips-bar-bg.png',
      OnionThemeImage.preview => null,
    };
    final url = Uri.parse('$baseUrl/themes/$name/$imagePath');
    return Image(
      image: NetworkImage(url.toString()),
      errorBuilder: (_, __, ___) => SizedBox.shrink(),
    )..image.resolve(ImageConfiguration()).addListener(
        ImageStreamListener(listener ?? (image, synchronousCall) {}));
  }
}

class OnionThemeConfig {
  final String? name;
  final String? author;
  final String? description;
  final _Font? hint;
  final _Font? title;
  final _Grid? grid;
  final _HideLabels? hideLabels;

  OnionThemeConfig._({
    required this.name,
    required this.author,
    required this.description,
    required this.hint,
    required this.hideLabels,
    required this.title,
    required this.grid,
  });

  factory OnionThemeConfig.fromJson(Map<String, dynamic> json) =>
      OnionThemeConfig._(
        name: json['name'],
        author: json['author'],
        description: json['description'],
        grid: json['grid'] == null ? null : _Grid.fromJson(json['grid']),
        hint: json['hint'] == null ? null : _Font.fromJson(json['hint']),
        title: json['title'] == null ? null : _Font.fromJson(json['title']),
        hideLabels: json['hideLabels'] == null
            ? null
            : _HideLabels.fromJson(json['hideLabels']),
      );
}

class _HideLabels {
  final bool icons;
  final bool hints;

  _HideLabels._({required this.icons, required this.hints});

  factory _HideLabels.fromJson(Map<String, dynamic> json) => switch (json) {
        {
          'icons': bool icons,
          'hints': bool hints,
        } =>
          _HideLabels._(icons: icons, hints: hints),
        _ => throw FormatException(json.toString()),
      };
}

class _Font {
  final String font;
  final int size;
  final String color;

  TextStyle get style {
    return DynamicFonts.getFont(
      font,
      color: HexColor(color),
      fontSize: size.toDouble(),
    );
  }

  _Font._({required this.font, required this.size, required this.color}) {
    _CFont.register(font);
  }

  factory _Font.fromJson(Map<String, dynamic> json) => switch (json) {
        {
          'font': String font,
          'size': int size,
          'color': String color,
        } =>
          _Font._(font: font, size: size, color: color),
        _ => throw FormatException(json.toString()),
      };
}

class _Grid {
  final String font;
  final String color;
  final int grid1x4;
  final int grid3x4;
  final String selectedColor;

  TextStyle get style1x4 {
    return DynamicFonts.getFont(
      font,
      color: HexColor(color),
      fontSize: grid1x4.toDouble(),
    );
  }

  TextStyle get selectedStyle1x4 {
    return style1x4.copyWith(color: HexColor(selectedColor), shadows: [
      ui.Shadow(
        offset: ui.Offset(2, 2),
        color: Colors.black,
      )
    ]);
  }

  TextStyle get style3x4 {
    return style1x4.copyWith(fontSize: grid3x4.toDouble());
  }

  TextStyle get selectedStyle3x4 {
    return style3x4.copyWith(color: HexColor(selectedColor));
  }

  _Grid._({
    required this.font,
    required this.color,
    required this.grid1x4,
    required this.grid3x4,
    required this.selectedColor,
  }) {
    _CFont.register(font);
  }

  factory _Grid.fromJson(Map<String, dynamic> json) => switch (json) {
        {
          'font': String font,
          'color': String color,
          'selectedcolor': String selectedColor,
          'grid1x4': int grid1x4,
          'grid3x4': int grid3x4,
        } =>
          _Grid._(
            font: font,
            color: color,
            selectedColor: selectedColor,
            grid1x4: grid1x4,
            grid3x4: grid3x4,
          ),
        _ => throw FormatException(json.toString()),
      };
}

class _CFont extends DynamicFontsFile {
  _CFont(this.path, String expectedFileHash, int expectedLength)
      : super(expectedFileHash, expectedLength);

  final String path;

  @override
  String get url => path;

  static void register(String font) async {
    try {
      final String token = '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';
      final String api =
          'https://api.github.com/repos/OnionUI/Themes/contents/';
      final name = (theme as NetworkOnionTheme).name;
      final String url = '$api/themes/$name/$font';
      final response = await get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final size = json['size'];
        final url = json['download_url'];
        final content = json['content']
            .replaceAll('\n', '')
            .replaceAll('\r', '')
            .replaceAll(' ', '');

        Uint8List bytes = base64.decode(content);
        Digest sha256Result = sha256.convert(bytes);
        String sha = sha256Result.toString();

        final cFont = _CFont(url, sha, size);
        DynamicFonts.register(font, {
          DynamicFontsVariant(
              fontWeight: FontWeight.normal,
              fontStyle: FontStyle.normal): cFont,
        });
      } else {
        log(response.body);
      }
    } catch (e) {
      log(e.toString());
    }
  }
}

// "batteryPercentage": {
// "visible": true,
// "font": "OpenSansCondensed-Bold.ttf",
// "size": 11,
// "color": "#FFFFFF",
// "textAlign": "center",
// "fixed": true,
// "offsetX": 0,
// "offsetY": 0
// },
// "title": {
// "font": "OpenSansCondensed-Bold.ttf",
// "size": 36,
// "color": "#FFFFFF"
// },
// "currentpage": {
// "color": "#FFFFFF"
// },
// "total": {
// "color": "#FFFFFF"
// },
// "list": {
// "font": "OpenSansCondensed-Bold.ttf",
// "size": 25,
// "color": "#FFFFFF"
// }
