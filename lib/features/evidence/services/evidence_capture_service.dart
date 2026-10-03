import 'package:image_picker/image_picker.dart';

class EvidenceCaptureService {
  EvidenceCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> takePhoto() {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      requestFullMetadata: false,
    );
  }

  Future<XFile?> selectPhoto() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      requestFullMetadata: false,
    );
  }

  Future<XFile?> recoverLostPhoto() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    return response.files?.firstOrNull;
  }
}
