import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  Future<String?> takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image?.path;
  }
}
