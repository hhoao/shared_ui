import 'package:flutter/widgets.dart';

abstract class TpMediaPreviewPort {
  Future<void> previewImage(BuildContext context, String path);

  Future<void> previewVideo(BuildContext context, String path);
}
