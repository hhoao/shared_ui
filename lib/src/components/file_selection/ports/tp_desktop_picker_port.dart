import '../models/tp_picked_entry.dart';

abstract class TpDesktopPickerPort {
  Future<List<TpPickedEntry>?> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    String? dialogTitle,
    String? initialDirectory,
    int? maxSelectionCount,
  });

  Future<List<TpPickedEntry>?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
  });
}
