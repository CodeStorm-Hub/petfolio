// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  test('Generate all app launcher icons from SVG programmatically', () async {
    // 1. Read the SVG string
    final svgString = File('app_icon_cropped.svg').readAsStringSync();

    // Helper to generate a PNG of a specific size using vg.loadPicture
    Future<void> generatePng(String outputPath, double size) async {
      final SvgStringLoader svgStringLoader = SvgStringLoader(svgString);
      final PictureInfo pictureInfo = await vg.loadPicture(svgStringLoader, null);
      
      try {
        final ui.Picture picture = pictureInfo.picture;
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final ui.Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
        
        // Scale canvas to target size
        canvas.scale(size / pictureInfo.size.width, size / pictureInfo.size.height);
        canvas.drawPicture(picture);
        
        final ui.Image image = await recorder.endRecording().toImage(
          size.ceil(),
          size.ceil(),
        );
        
        final ByteData? bytesData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = bytesData!.buffer.asUint8List();

        final file = File(outputPath);
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        file.writeAsBytesSync(pngBytes);
        print('Successfully generated: $outputPath (${size.toInt()}x${size.toInt()})');
      } finally {
        pictureInfo.picture.dispose();
      }
    }

    // Android Icons
    await generatePng('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48);
    await generatePng('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72);
    await generatePng('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96);
    await generatePng('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144);
    await generatePng('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192);

    // iOS Icons
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png', 20);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png', 40);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png', 60);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png', 29);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png', 58);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png', 87);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png', 40);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png', 80);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png', 120);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png', 120);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png', 180);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png', 76);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png', 152);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png', 167);
    await generatePng('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', 1024);

    // Web Icons
    await generatePng('web/favicon.png', 32);
    await generatePng('web/icons/Icon-192.png', 192);
    await generatePng('web/icons/Icon-512.png', 512);
    await generatePng('web/icons/Icon-maskable-192.png', 192);
    await generatePng('web/icons/Icon-maskable-512.png', 512);
  });
}
