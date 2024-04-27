import 'package:flutter/material.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

abstract class OnionTheme {
  Widget get screenOff;
  Widget get screenOffSave;
  Widget get bootScreen;
  Widget get chargingState0;
  Widget get chargingState1;
  Widget get chargingState2;
  Widget get chargingState3;
  Widget get chargingState4;
  Widget get chargingState5;
  Widget get chargingState6;
  Widget get chargingState7;
  Widget get chargingState8;
  Widget get chargingState9;
  Widget get chargingState10;
  Widget get chargingState11;
  Widget get chargingState12;
  Widget get chargingState13;
  Widget get chargingState14;
  Widget get chargingState15;
  Widget get chargingState16;
  Widget get chargingState17;
  Widget get chargingState18;
  Widget get chargingState19;
  Widget get chargingState20;
  Widget get chargingState21;
  Widget get chargingState22;
  Widget get chargingState23;
  Widget get gsBottomBart;
  Widget get gsTopBar;
  Widget get lowBat;
  Widget get lum0;
  Widget get lum1;
  Widget get lum2;
  Widget get lum3;
  Widget get lum4;
  Widget get lum5;
  Widget get lum6;
  Widget get lum7;
  Widget get lum8;
  Widget get lum9;
  Widget get lum10;
  Widget get toggleOff;
  Widget get toggleOn;
  Widget get empty;
  Widget get background;
  Widget get bgButtonF;
  Widget get bgGameItemF;
  Widget get bgGameItemN;
  Widget get bgIoTesting;
  Widget get bgKeySettingF;
  Widget get bgKeySetting;
  Widget get bgListL;
  Widget get bgListS;
  Widget get bgPopMenu1;
  Widget get bgPopMenu2;
  Widget get bgPopMenu3;
  Widget get bgPopMenu4;
  Widget get bgRaListItem;
  Widget get bgTitle;
  Widget get color;
  Widget get divLineH;
  Widget get divLineV01;
  Widget get dotA;
  Widget get dotN;
  Widget get fixit;
  Widget get headphoneIcon;
  Widget get icMENUA;
  Widget get icMENU;
  Widget get icAppF;
  Widget get icAppN;
  Widget get icFavoriteF;
  Widget get icFavoriteMark;
  Widget get icFavoriteN;
  Widget get icGameF;
  Widget get icGameN;
  Widget get icPowerCharge100;
  Widget get icRecentF;
  Widget get icRecentN;
  Widget get icRetroarchF;
  Widget get icRetroarchN;
  Widget get icSettingF;
  Widget get icSettingN;
  Widget get iconA54;
  Widget get iconB54;
  Widget get iconShutdown;
  Widget get iconTF;
  Widget get iconBrightness48;
  Widget get iconDeviceInfo48;
  Widget get iconFactoryReset48;
  Widget get iconFolder;
  Widget get iconGame;
  Widget get iconKeySetting48;
  Widget get iconLanguage48;
  Widget get iconLeftArrow24;
  Widget get iconRightArrow24;
  Widget get iconSettingWifi;
  Widget get iconWifiConnected;
  Widget get iconWifiLocked;
  Widget get iconWifiSignal01;
  Widget get iconWifiSignal02;
  Widget get iconWifiSignal03;
  Widget get iconWifiSignal04;
  Widget get listNum;
  Widget get miyooTopbar;
  Widget get numBg;
  Widget get popBg;
  Widget get power0Icon;
  Widget get power20Icon;
  Widget get power50Icon;
  Widget get power80Icon;
  Widget get powerFullIcon;
  Widget get previewBg;
  Widget get progressDot;
  Widget get soundIcon;
  Widget get thumbDefault;
  Widget get tipsBarBg;
  Widget get preview;
}

class NetworkOnionTheme extends OnionTheme {
  final String baseUrl =
      'https://raw.githubusercontent.com/OnionUI/Themes/main/';
  final String themePath;

  NetworkOnionTheme({required this.themePath});

  @override
  Widget get screenOff =>
      Image.network('$baseUrl/$themePath/skin/extra/Screen_Off.png');

  @override
  Widget get screenOffSave =>
      Image.network('$baseUrl/$themePath/skin/extra/Screen_Off_Save.png');

  @override
  Widget get bootScreen =>
      Image.network('$baseUrl/$themePath/skin/extra/bootScreen.png');

  @override
  Widget get chargingState0 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState0.png');

  @override
  Widget get chargingState1 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState1.png');

  @override
  Widget get chargingState2 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState2.png');

  @override
  Widget get chargingState3 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState3.png');

  @override
  Widget get chargingState4 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState4.png');

  @override
  Widget get chargingState5 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState5.png');

  @override
  Widget get chargingState6 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState6.png');

  @override
  Widget get chargingState7 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState7.png');

  @override
  Widget get chargingState8 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState8.png');

  @override
  Widget get chargingState9 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState9.png');

  @override
  Widget get chargingState10 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState10.png');

  @override
  Widget get chargingState11 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState11.png');

  @override
  Widget get chargingState12 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState12.png');

  @override
  Widget get chargingState13 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState13.png');

  @override
  Widget get chargingState14 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState14.png');

  @override
  Widget get chargingState15 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState15.png');

  @override
  Widget get chargingState16 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState16.png');

  @override
  Widget get chargingState17 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState17.png');

  @override
  Widget get chargingState18 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState18.png');

  @override
  Widget get chargingState19 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState19.png');

  @override
  Widget get chargingState20 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState20.png');

  @override
  Widget get chargingState21 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState21.png');

  @override
  Widget get chargingState22 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState22.png');

  @override
  Widget get chargingState23 =>
      Image.network('$baseUrl/$themePath/skin/extra/chargingState23.png');

  @override
  Widget get gsBottomBart =>
      Image.network('$baseUrl/$themePath/skin/extra/gs-bottom-bar.png');

  @override
  Widget get gsTopBar =>
      Image.network('$baseUrl/$themePath/skin/extra/gs-top-bar.png');

  @override
  Widget get lowBat =>
      Image.network('$baseUrl/$themePath/skin/extra/lowBat.png');

  @override
  Widget get lum0 => Image.network('$baseUrl/$themePath/skin/extra/lum0.png');

  @override
  Widget get lum1 => Image.network('$baseUrl/$themePath/skin/extra/lum1.png');

  @override
  Widget get lum2 => Image.network('$baseUrl/$themePath/skin/extra/lum2.png');

  @override
  Widget get lum3 => Image.network('$baseUrl/$themePath/skin/extra/lum3.png');

  @override
  Widget get lum4 => Image.network('$baseUrl/$themePath/skin/extra/lum4.png');

  @override
  Widget get lum5 => Image.network('$baseUrl/$themePath/skin/extra/lum5.png');

  @override
  Widget get lum6 => Image.network('$baseUrl/$themePath/skin/extra/lum6.png');

  @override
  Widget get lum7 => Image.network('$baseUrl/$themePath/skin/extra/lum7.png');

  @override
  Widget get lum8 => Image.network('$baseUrl/$themePath/skin/extra/lum8.png');

  @override
  Widget get lum9 => Image.network('$baseUrl/$themePath/skin/extra/lum9.png');

  @override
  Widget get lum10 => Image.network('$baseUrl/$themePath/skin/extra/lum10.png');

  @override
  Widget get toggleOff =>
      Image.network('$baseUrl/$themePath/skin/extra/toggle-off.png');

  @override
  Widget get toggleOn =>
      Image.network('$baseUrl/$themePath/skin/extra/toggle-on.png');

  @override
  Widget get empty => Image.network('$baseUrl/$themePath/skin/Empty.png');

  @override
  Widget get background =>
      Image.network('$baseUrl/$themePath/skin/background.png');

  @override
  Widget get bgButtonF =>
      Image.network('$baseUrl/$themePath/skin/bg-button-f.png');

  @override
  Widget get bgGameItemF =>
      Image.network('$baseUrl/$themePath/skin/bg-game-item-f.png');

  @override
  Widget get bgGameItemN =>
      Image.network('$baseUrl/$themePath/skin/bg-game-item-n.png');

  @override
  Widget get bgIoTesting =>
      Image.network('$baseUrl/$themePath/skin/bg-io-testing.png');

  @override
  Widget get bgKeySettingF =>
      Image.network('$baseUrl/$themePath/skin/bg-keysetting-f.png');

  @override
  Widget get bgKeySetting =>
      Image.network('$baseUrl/$themePath/skin/bg-keysetting.png');

  @override
  Widget get bgListL => Image.network('$baseUrl/$themePath/skin/bg-list-l.png');

  @override
  Widget get bgListS => Image.network('$baseUrl/$themePath/skin/bg-list-s.png');

  @override
  Widget get bgPopMenu1 =>
      Image.network('$baseUrl/$themePath/skin/bg-pop-menu-1.png');

  @override
  Widget get bgPopMenu2 =>
      Image.network('$baseUrl/$themePath/skin/bg-pop-menu-2.png');

  @override
  Widget get bgPopMenu3 =>
      Image.network('$baseUrl/$themePath/skin/bg-pop-menu-3.png');

  @override
  Widget get bgPopMenu4 =>
      Image.network('$baseUrl/$themePath/skin/bg-pop-menu-4.png');

  @override
  Widget get bgRaListItem =>
      Image.network('$baseUrl/$themePath/skin/bg-ra-list-item.png');

  @override
  Widget get bgTitle => Image.network('$baseUrl/$themePath/skin/bg-title.png');

  @override
  Widget get color => Image.network('$baseUrl/$themePath/skin/color.png');

  @override
  Widget get divLineH =>
      Image.network('$baseUrl/$themePath/skin/div-line-h.png');

  @override
  Widget get divLineV01 =>
      Image.network('$baseUrl/$themePath/skin/div-line-v-01.png');

  @override
  Widget get dotA => Image.network('$baseUrl/$themePath/skin/dot-a.png');

  @override
  Widget get dotN => Image.network('$baseUrl/$themePath/skin/dot-n.png');

  @override
  Widget get fixit => Image.network('$baseUrl/$themePath/skin/fixit.png');

  @override
  Widget get headphoneIcon =>
      Image.network('$baseUrl/$themePath/skin/headphone-icon.png');

  @override
  Widget get icMENUA => Image.network('$baseUrl/$themePath/skin/ic-MENU+A.png');

  @override
  Widget get icMENU => Image.network('$baseUrl/$themePath/skin/ic-MENU.png');

  @override
  Widget get icAppF => Image.network('$baseUrl/$themePath/skin/ic-app-f.png');

  @override
  Widget get icAppN => Image.network('$baseUrl/$themePath/skin/ic-app-n.png');

  @override
  Widget get icFavoriteF =>
      Image.network('$baseUrl/$themePath/skin/ic-favorite-f.png');

  @override
  Widget get icFavoriteMark =>
      Image.network('$baseUrl/$themePath/skin/ic-favorite-mark.png');

  @override
  Widget get icFavoriteN =>
      Image.network('$baseUrl/$themePath/skin/ic-favorite-n.png');

  @override
  Widget get icGameF => Image.network('$baseUrl/$themePath/skin/ic-game-f.png');

  @override
  Widget get icGameN => Image.network('$baseUrl/$themePath/skin/ic-game-n.png');

  @override
  Widget get icPowerCharge100 =>
      Image.network('$baseUrl/$themePath/skin/ic-power-charge-100%.png');

  @override
  Widget get icRecentF =>
      Image.network('$baseUrl/$themePath/skin/ic-recent-f.png');

  @override
  Widget get icRecentN =>
      Image.network('$baseUrl/$themePath/skin/ic-recent-n.png');

  @override
  Widget get icRetroarchF =>
      Image.network('$baseUrl/$themePath/skin/ic-retroarch-f.png');

  @override
  Widget get icRetroarchN =>
      Image.network('$baseUrl/$themePath/skin/ic-retroarch-n.png');

  @override
  Widget get icSettingF =>
      Image.network('$baseUrl/$themePath/skin/ic-setting-f.png');

  @override
  Widget get icSettingN =>
      Image.network('$baseUrl/$themePath/skin/ic-setting-n.png');

  @override
  Widget get iconA54 => Image.network('$baseUrl/$themePath/skin/icon-A-54.png');

  @override
  Widget get iconB54 => Image.network('$baseUrl/$themePath/skin/icon-B-54.png');

  @override
  Widget get iconShutdown =>
      Image.network('$baseUrl/$themePath/skin/icon-Shutdown.png');

  @override
  Widget get iconTF => Image.network('$baseUrl/$themePath/skin/icon-TF.png');

  @override
  Widget get iconBrightness48 =>
      Image.network('$baseUrl/$themePath/skin/icon-brightness-48.png');

  @override
  Widget get iconDeviceInfo48 =>
      Image.network('$baseUrl/$themePath/skin/icon-device-info-48.png');

  @override
  Widget get iconFactoryReset48 =>
      Image.network('$baseUrl/$themePath/skin/icon-factory-reset-48.png');

  @override
  Widget get iconFolder =>
      Image.network('$baseUrl/$themePath/skin/icon-folder.png');

  @override
  Widget get iconGame =>
      Image.network('$baseUrl/$themePath/skin/icon-game.png');

  @override
  Widget get iconKeySetting48 =>
      Image.network('$baseUrl/$themePath/skin/icon-key-setting-48.png');

  @override
  Widget get iconLanguage48 =>
      Image.network('$baseUrl/$themePath/skin/icon-language-48.png');

  @override
  Widget get iconLeftArrow24 =>
      Image.network('$baseUrl/$themePath/skin/icon-left-arrow-24.png');

  @override
  Widget get iconRightArrow24 =>
      Image.network('$baseUrl/$themePath/skin/icon-right-arrow-24.png');

  @override
  Widget get iconSettingWifi =>
      Image.network('$baseUrl/$themePath/skin/icon-setting-wifi.png');

  @override
  Widget get iconWifiConnected =>
      Image.network('$baseUrl/$themePath/skin/icon-wifi-connected.png');

  @override
  Widget get iconWifiLocked =>
      Image.network('$baseUrl/$themePath/skin/icon-wifi-locked.png');

  @override
  Widget get iconWifiSignal01 =>
      Image.network('$baseUrl/$themePath/skin/icon-wifi-signal-01.png');

  @override
  Widget get iconWifiSignal02 =>
      Image.network('$baseUrl/$themePath/skin/icon-wifi-signal-02.png');

  @override
  Widget get iconWifiSignal03 =>
      Image.network('$baseUrl/$themePath/skin/icon-wifi-signal-03.png');

  @override
  Widget get iconWifiSignal04 =>
      Image.network('$baseUrl/$themePath/skin/icon-wifi-signal-04.png');

  @override
  Widget get listNum => Image.network('$baseUrl/$themePath/skin/list-num.png');

  @override
  Widget get miyooTopbar =>
      Image.network('$baseUrl/$themePath/skin/miyoo-topbar.png');

  @override
  Widget get numBg => Image.network('$baseUrl/$themePath/skin/num-bg.png');

  @override
  Widget get popBg => Image.network('$baseUrl/$themePath/skin/pop-bg.png');

  @override
  Widget get power0Icon =>
      Image.network('$baseUrl/$themePath/skin/power-0%-icon.png');

  @override
  Widget get power20Icon =>
      Image.network('$baseUrl/$themePath/skin/power-20%-icon.png');

  @override
  Widget get power50Icon =>
      Image.network('$baseUrl/$themePath/skin/power-50%-icon.png');

  @override
  Widget get power80Icon =>
      Image.network('$baseUrl/$themePath/skin/power-80%-icon.png');

  @override
  Widget get powerFullIcon =>
      Image.network('$baseUrl/$themePath/skin/power-full-icon.png');

  @override
  Widget get previewBg =>
      Image.network('$baseUrl/$themePath/skin/preview-bg.png');

  @override
  Widget get progressDot =>
      Image.network('$baseUrl/$themePath/skin/progress-dot.png');

  @override
  Widget get soundIcon =>
      Image.network('$baseUrl/$themePath/skin/sound-icon.png');

  @override
  Widget get thumbDefault =>
      Image.network('$baseUrl/$themePath/skin/thumb-default.png');

  @override
  Widget get tipsBarBg =>
      Image.network('$baseUrl/$themePath/skin/tips-bar-bg.png');

  @override
  Widget get preview => Image.network('$baseUrl/$themePath/preview.png',
      width: 640, height: 480, fit: BoxFit.cover);
}
