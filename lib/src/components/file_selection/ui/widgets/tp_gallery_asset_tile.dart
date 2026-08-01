import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../theme/tp_text_styles.dart';
import '../../../hover/tp_hover.dart';
import '../../../icon_button/tp_icon_button.dart';
import '../../models/tp_gallery_models.dart';
import '../tp_file_selection_strings.dart';

typedef TpGalleryAssetTap = void Function(TpGalleryAsset asset);
typedef TpGalleryAssetPreview = void Function(TpGalleryAsset asset);

class TpGalleryAssetTile extends StatefulWidget {
  const TpGalleryAssetTile({
    super.key,
    required this.asset,
    required this.strings,
    required this.isSelected,
    required this.onTap,
    required this.loadThumbnail,
    this.onPreview,
  });

  final TpGalleryAsset asset;
  final TpFileSelectionStrings strings;
  final bool isSelected;
  final TpGalleryAssetTap onTap;
  final Future<Uint8List?> Function() loadThumbnail;
  final TpGalleryAssetPreview? onPreview;

  @override
  State<TpGalleryAssetTile> createState() => _TpGalleryAssetTileState();
}

class _TpGalleryAssetTileState extends State<TpGalleryAssetTile> {
  Uint8List? _thumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(TpGalleryAssetTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    setState(() => _isLoading = true);
    final bytes = await widget.loadThumbnail();
    if (!mounted) return;
    setState(() {
      _thumbnail = bytes;
      _isLoading = false;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return TpHover(
      onTap: () => widget.onTap(widget.asset),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        key: Key('tp_gallery_asset_tile_${widget.asset.id}'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: widget.isSelected
              ? Border.all(color: cs.primary, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: _buildThumbnail(cs),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? cs.primary
                      : Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.onPrimary, width: 1),
                ),
                child: widget.isSelected
                    ? Icon(Icons.check, color: cs.onPrimary, size: 8)
                    : null,
              ),
            ),
            if (widget.onPreview != null)
              Positioned(
                top: 4,
                right: 4,
                child: TpIconButton(
                  key: Key('tp_gallery_preview_${widget.asset.id}'),
                  icon: widget.asset.isVideo
                      ? Icons.play_arrow
                      : Icons.visibility_outlined,
                  tooltip: widget.strings.previewTitle,
                  size: 24,
                  iconSize: 14,
                  compact: true,
                  color: cs.onPrimary,
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  onTap: () => widget.onPreview!(widget.asset),
                ),
              ),
            if (widget.asset.isVideo && widget.asset.duration != null)
              Positioned(
                bottom: 4,
                right: 4,
                child: Text(
                  _formatDuration(widget.asset.duration!),
                  style: styles.xsMediumColored(cs.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme cs) {
    if (_thumbnail != null) {
      return Image.memory(
        _thumbnail!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          widget.asset.isVideo ? Icons.videocam : Icons.image,
          color: cs.onSurfaceVariant,
          size: 32,
        ),
      );
    }
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.primary,
          ),
        ),
      );
    }
    return Icon(
      widget.asset.isVideo ? Icons.videocam : Icons.image,
      color: cs.onSurfaceVariant,
      size: 32,
    );
  }
}
