import 'package:image_picker/image_picker.dart';

Future<XFile?> pickGalleryImage({
  int? maxWidth,
  int? imageQuality,
}) {
  return ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth?.toDouble(),
    imageQuality: imageQuality,
  );
}
