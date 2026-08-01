enum TpFsEntryKind { file, directory, other }

class TpFsEntry {
  const TpFsEntry({
    required this.path,
    required this.name,
    required this.kind,
    this.modifiedAt,
    this.sizeBytes,
  });

  final String path;
  final String name;
  final TpFsEntryKind kind;
  final DateTime? modifiedAt;
  final int? sizeBytes;
}

class TpFilesystemRoot {
  const TpFilesystemRoot({
    required this.id,
    required this.label,
    required this.path,
  });

  final String id;
  final String label;
  final String path;
}
