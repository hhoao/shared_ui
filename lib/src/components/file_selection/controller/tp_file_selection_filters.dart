import '../models/tp_fs_entry.dart';

enum TpGalleryMediaKind { image, video, all }

const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp'};
const _videoExtensions = {'mp4', 'mov', 'mkv', 'webm'};

List<TpFsEntry> filterFsEntries(
  List<TpFsEntry> entries, {
  List<String>? allowedExtensions,
  bool showHiddenFiles = false,
  String query = '',
}) {
  final normalizedExtensions = _normalizeExtensions(allowedExtensions);
  final normalizedQuery = query.trim().toLowerCase();

  return entries.where((entry) {
    if (!showHiddenFiles && entry.name.startsWith('.')) {
      return false;
    }

    if (normalizedQuery.isNotEmpty &&
        !entry.name.toLowerCase().contains(normalizedQuery)) {
      return false;
    }

    if (normalizedExtensions != null &&
        entry.kind == TpFsEntryKind.file &&
        !_matchesExtension(entry.name, normalizedExtensions)) {
      return false;
    }

    return true;
  }).toList();
}

List<TpFsEntry> sortFsEntries(
  List<TpFsEntry> entries, {
  required String sortType,
  bool ascending = true,
}) {
  final sorted = List<TpFsEntry>.from(entries);
  sorted.sort((a, b) {
    final directoryOrder = _compareDirectoriesFirst(a, b);
    if (directoryOrder != 0) {
      return directoryOrder;
    }

    final result = switch (sortType) {
      'date' => _compareNullableDate(a.modifiedAt, b.modifiedAt),
      'size' => _compareNullableInt(a.sizeBytes, b.sizeBytes),
      'type' => _extensionOf(a.name).compareTo(_extensionOf(b.name)),
      _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };

    return ascending ? result : -result;
  });
  return sorted;
}

TpGalleryMediaKind resolveGalleryMediaFilter(List<String>? allowedExtensions) {
  if (allowedExtensions == null || allowedExtensions.isEmpty) {
    return TpGalleryMediaKind.all;
  }

  final extensions = allowedExtensions
      .map((ext) => _normalizeExtension(ext))
      .where((ext) => ext.isNotEmpty)
      .toSet();

  final hasImages = extensions.any(_imageExtensions.contains);
  final hasVideos = extensions.any(_videoExtensions.contains);

  if (hasImages && !hasVideos) {
    return TpGalleryMediaKind.image;
  }
  if (hasVideos && !hasImages) {
    return TpGalleryMediaKind.video;
  }
  return TpGalleryMediaKind.all;
}

Set<String>? _normalizeExtensions(List<String>? allowedExtensions) {
  if (allowedExtensions == null || allowedExtensions.isEmpty) {
    return null;
  }

  return allowedExtensions.map(_normalizeExtension).toSet();
}

String _normalizeExtension(String extension) {
  final trimmed = extension.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return '';
  }
  return trimmed.startsWith('.') ? trimmed.substring(1) : trimmed;
}

bool _matchesExtension(String fileName, Set<String> allowedExtensions) {
  final extension = _extensionOf(fileName);
  return allowedExtensions.contains(extension);
}

String _extensionOf(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
    return '';
  }
  return fileName.substring(dotIndex + 1).toLowerCase();
}

int _compareDirectoriesFirst(TpFsEntry a, TpFsEntry b) {
  final aIsDirectory = a.kind == TpFsEntryKind.directory;
  final bIsDirectory = b.kind == TpFsEntryKind.directory;
  if (aIsDirectory && !bIsDirectory) {
    return -1;
  }
  if (!aIsDirectory && bIsDirectory) {
    return 1;
  }
  return 0;
}

int _compareNullableDate(DateTime? a, DateTime? b) {
  if (a == null && b == null) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}

int _compareNullableInt(int? a, int? b) {
  if (a == null && b == null) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}
