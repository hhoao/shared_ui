import '../ui/tp_file_selection_strings.dart';
import 'tp_desktop_picker_port.dart';
import 'tp_filesystem_port.dart';
import 'tp_gallery_port.dart';
import 'tp_media_preview_port.dart';
import 'tp_permission_port.dart';

class TpFileSelectionDeps {
  const TpFileSelectionDeps({
    required this.filesystem,
    required this.permission,
    this.gallery,
    this.desktop,
    this.preview,
    required this.strings,
    required this.isDesktop,
  });

  final TpFilesystemPort filesystem;
  final TpPermissionPort permission;
  final TpGalleryPort? gallery;
  final TpDesktopPickerPort? desktop;
  final TpMediaPreviewPort? preview;
  final TpFileSelectionStrings strings;
  final bool Function() isDesktop;
}
