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
}) {
  return ImagePicker().pickImage(
    source: source,
    maxWidth: maxWidth?.toDouble(),
    imageQuality: imageQuality ?? 82,
    requestFullMetadata: false,
  );
}

Future<XFile> prepareImageForUpload(
  XFile source, {
  int? maxWidth,
  int? quality,
}) async =>
    source;
