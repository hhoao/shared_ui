import 'package:equatable/equatable.dart';

enum TpPickedKind { file, directory }

class TpPickedEntry extends Equatable {
  const TpPickedEntry({
    required this.path,
    required this.kind,
    this.displayName,
    this.mimeType,
  });

  final String path;
  final TpPickedKind kind;
  final String? displayName;
  final String? mimeType;

  @override
  List<Object?> get props => [path, kind, displayName, mimeType];
}
