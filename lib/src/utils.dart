
import 'dart:developer';

import 'package:flutter/material.dart';

void delayed(void Function() action, {int t = 3000}) async {
  await Future.delayed(Duration(milliseconds: t));
  action.call();
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}