import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> pickGalleryImage({
  int? maxWidth,
  int? imageQuality,
}) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    requestFullMetadata: false,
  );
  if (picked == null) return null;
  return _compress(picked, maxWidth: maxWidth, quality: imageQuality ?? 82);
}

Future<XFile> _compress(XFile source, {int? maxWidth, required int quality}) async {
  final bytes = await source.readAsBytes();
  final compressed = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: maxWidth ?? 1080,
    minHeight: maxWidth ?? 1080,
    quality: quality,
    format: CompressFormat.jpeg,
  );
  // Write to a temp file so callers can use XFile.path
  final dir = Directory.systemTemp;
  final outPath = '${dir.path}/${source.name.replaceAll(RegExp(r'\.[^.]+$'), '')}_c.jpg';
  final outFile = File(outPath);
  await outFile.writeAsBytes(compressed);
  return XFile(outPath, mimeType: 'image/jpeg');
}
