import 'package:flutter/foundation.dart';
import 'package:onion_device_preview/src/onion_theme.dart';

class OnionPreviewController {

  ValueNotifier<int> focusedIndex = ValueNotifier(0);

  final length = 4-1;

  void up() {

  }
  void down() {

  }
  void left() {
    focusedIndex.value--;
    if(focusedIndex.value < 0) focusedIndex.value = length;
  }
  void right() {
    focusedIndex.value++;
    if(focusedIndex.value >= length) focusedIndex.value = 0;
  }
}