import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> pickGalleryImage({
  int? maxWidth,
  int? imageQuality,
}) =>
    pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );

Future<XFile?> pickImage({
  required ImageSource source,
  int? maxWidth,
  int? imageQuality,
}) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    requestFullMetadata: false,
  );
  if (picked == null) return null;
  return prepareImageForUpload(
    picked,
    maxWidth: maxWidth,
    quality: imageQuality ?? 82,
  );
}

Future<XFile> prepareImageForUpload(
  XFile source, {
  int? maxWidth,
  required int quality,
}) =>
    _compress(source, maxWidth: maxWidth, quality: quality);

Future<XFile> _compress(
  XFile source, {
  int? maxWidth,
  required int quality,
}) async {
  final bytes = await source.readAsBytes();
  final compressed = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: maxWidth ?? 1080,
    minHeight: maxWidth ?? 1080,
    quality: quality,
    format: CompressFormat.jpeg,
  );
  final dir = Directory.systemTemp;
  final outPath =
      '${dir.path}/${source.name.replaceAll(RegExp(r'\.[^.]+$'), '')}_c.jpg';
  final outFile = File(outPath);
  await outFile.writeAsBytes(compressed);
  return XFile(outPath, mimeType: 'image/jpeg');
}
