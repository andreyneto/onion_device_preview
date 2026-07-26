import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

/// Zips a real theme directory from the sibling `../Themes` checkout, so
/// [OnionThemeBundle] is exercised against actual theme content (not just
/// synthetic fixtures). Skips gracefully if the checkout isn't present.
Uint8List? _zipRealTheme(String themeDirName) {
  final dir = Directory('../Themes/themes/$themeDirName');
  if (!dir.existsSync()) return null;

  final archive = Archive();
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final relative = entity.path.substring(dir.path.length + 1).replaceAll('\\', '/');
    final bytes = entity.readAsBytesSync();
    archive.addFile(ArchiveFile(relative, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  test('Blueprint by Aemiii91, zipped from the real Themes checkout', () {
    final zip = _zipRealTheme('Blueprint by Aemiii91');
    if (zip == null) {
      markTestSkipped('../Themes checkout not found next to this package');
      return;
    }

    final bundle = OnionThemeBundle.fromZipBytes(zip);

    expect(bundle.isPack, isFalse);
    expect(bundle.config.name, 'Blueprint');
    expect(bundle.config.author, 'Aemiii91');
    expect(bundle.config.batteryPercentage.visible, isTrue);
    expect(bundle.config.batteryPercentage.textAlign, OnionTextAlign.center);
    expect(bundle['skin/background.png'], isNotNull);
    expect(bundle['preview.png'], isNotNull);
  });

  test('a real theme pack exposes every subtheme as a root', () {
    // A known 3-theme pack from the community Themes repo (see plan.md §6).
    final zip = _zipRealTheme('AnalogPhosphor (3-pack) by trash');
    if (zip == null) {
      markTestSkipped('../Themes checkout not found next to this package');
      return;
    }

    final bundle = OnionThemeBundle.fromZipBytes(zip);

    expect(bundle.isPack, isTrue);
    expect(bundle.availableRoots.length, greaterThanOrEqualTo(2));
  });
}
