import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/i18n/i18n.dart';
import '../upload_controller.dart';
import '../upload_model.dart';
import '../upload_section.dart';

class UploadPhotoSection extends StatelessWidget {
  const UploadPhotoSection({super.key, required this.controller});

  final UploadController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final uploading = controller.uploading;
    final canAdd = !uploading && controller.canAddPhoto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UploadSectionLabel(
          context.t(S.photos),
          trailing: '${controller.photos.length}/$maxPostPhotos',
          required: true,
        ),
        const SizedBox(height: 8),
        _PhotoGrid(
          photos: controller.photos,
          enabled: !uploading,
          onAdd: controller.canAddPhoto ? controller.pickFromGallery : null,
          onRemove: controller.removePhoto,
          onReorder: controller.reorderPhotos,
        ),
        const SizedBox(height: 8),
        UploadActionPair(
          first: UploadAction(
            label: context.t(S.library),
            icon: FontAwesomeIcons.images,
            onPressed: canAdd ? controller.pickFromGallery : null,
          ),
          second: UploadAction(
            label: context.t(S.camera),
            icon: FontAwesomeIcons.camera,
            onPressed: canAdd ? controller.pickFromCamera : null,
          ),
        ),
        if (controller.detectingExif) ...[
          const SizedBox(height: 8),
          Text(
            context.t(S.readingPhotoDetails),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  final List<UploadPhoto> photos;
  final bool enabled;
  final VoidCallback? onAdd;
  final ValueChanged<String> onRemove;
  final void Function(String id, int toIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final columns = constraints.maxWidth >= 560 ? 4 : 3;
        final extent = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < photos.length; index++)
              _PhotoTile(
                key: ValueKey(photos[index].id),
                photo: photos[index],
                index: index,
                count: photos.length,
                extent: extent,
                enabled: enabled,
                onRemove: onRemove,
                onReorder: onReorder,
              ),
            if (onAdd != null) _AddPhotoTile(extent: extent, onPressed: onAdd),
          ],
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.index,
    required this.count,
    required this.extent,
    required this.enabled,
    required this.onRemove,
    required this.onReorder,
  });

  final UploadPhoto photo;
  final int index;
  final int count;
  final double extent;
  final bool enabled;
  final ValueChanged<String> onRemove;
  final void Function(String id, int toIndex) onReorder;

  bool get _canDrag => enabled && count > 1;

  @override
  Widget build(BuildContext context) {
    final face = _PhotoFace(
      photo: photo,
      index: index,
      enabled: enabled,
      showDragHandle: _canDrag,
      onRemove: onRemove,
    );
    final tile = SizedBox(width: extent, height: extent, child: face);
    if (!_canDrag) return tile;

    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: extent,
      height: extent,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => details.data != photo.id,
        onAcceptWithDetails: (details) => onReorder(details.data, index),
        builder: (context, candidate, _) {
          return LongPressDraggable<String>(
            data: photo.id,
            delay: const Duration(milliseconds: 100),
            dragAnchorStrategy: childDragAnchorStrategy,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: extent,
                height: extent,
                child: _PhotoFace(
                  photo: photo,
                  index: index,
                  enabled: false,
                  showDragHandle: true,
                  showRemove: false,
                  onRemove: onRemove,
                ),
              ),
            ),
            childWhenDragging: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(width: extent, height: extent),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                face,
                if (candidate.isNotEmpty)
                  const IgnorePointer(child: _DropOutline()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DropOutline extends StatelessWidget {
  const _DropOutline();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary, width: 2),
      ),
    );
  }
}

class _PhotoFace extends StatelessWidget {
  const _PhotoFace({
    required this.photo,
    required this.index,
    required this.enabled,
    required this.showDragHandle,
    required this.onRemove,
    this.showRemove = true,
  });

  final UploadPhoto photo;
  final int index;
  final bool enabled;
  final bool showDragHandle;
  final bool showRemove;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compressing = photo.isCompressing;
    final failed = photo.compressionFailed;
    final handleBottom = failed ? 28.0 : (compressing ? 10.0 : 6.0);
    return Semantics(
      label: showDragHandle
          ? 'Photo ${index + 1}. Long press and drag to reorder.'
          : 'Photo ${index + 1}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: colors.surfaceContainerHigh,
              child: _photoPreview(photo, colors),
            ),
            Positioned(left: 6, top: 6, child: _IndexBadge(index: index + 1)),
            if (showRemove)
              Positioned(
                right: 6,
                top: 6,
                child: IconButton(
                  tooltip: context.t(S.removePhoto),
                  onPressed: enabled ? () => _confirmRemove(context) : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.55),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black.withValues(
                      alpha: 0.35,
                    ),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.7,
                    ),
                    overlayColor: Colors.white.withValues(alpha: 0.16),
                    fixedSize: const Size(22, 22),
                    minimumSize: const Size(22, 22),
                    maximumSize: const Size(22, 22),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.standard,
                    iconSize: 12,
                    shape: const CircleBorder(),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.xmark),
                ),
              ),
            if (showDragHandle)
              Positioned(
                left: 0,
                right: 0,
                bottom: handleBottom,
                child: const Center(child: _DragIndicator()),
              ),
            if (failed)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CompressionFailedBar(),
              )
            else if (compressing)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CompressionBar(
                  progress: photo.compressionProgress ?? 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(context.t(S.removePhotoConfirm)),
        ),
        actions: [
          M3EButton(
            onPressed: () => Navigator.pop(context, false),
            style: M3EButtonStyle.text,
            child: Text(context.t(S.cancel)),
          ),
          M3EButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t(S.remove)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onRemove(photo.id);
  }

  Widget _photoPreview(UploadPhoto photo, ColorScheme colors) {
    final previewUrl = photo.previewUrl;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: previewUrl,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        errorWidget: (_, _, _) =>
            Icon(Icons.image_outlined, color: colors.onSurfaceVariant),
      );
    }
    if (photo.path.isEmpty) {
      return Icon(Icons.image_outlined, color: colors.onSurfaceVariant);
    }
    return Image.file(
      File(photo.path),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) =>
          Icon(Icons.image_outlined, color: colors.onSurfaceVariant),
    );
  }
}

class _CompressionBar extends StatefulWidget {
  const _CompressionBar({required this.progress});

  final double progress;

  @override
  State<_CompressionBar> createState() => _CompressionBarState();
}

class _CompressionBarState extends State<_CompressionBar> {
  static const _tick = Duration(milliseconds: 160);
  Timer? _timer;
  double _shown = 0;

  @override
  void initState() {
    super.initState();
    _shown = widget.progress;
    _timer = Timer.periodic(_tick, (_) => _advance());
  }

  @override
  void didUpdateWidget(covariant _CompressionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress > _shown) _shown = widget.progress;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _ceiling(double progress) => progress < 0.75 ? 0.7 : 0.94;

  void _advance() {
    if (!mounted || widget.progress <= 0) return;
    final ceiling = _ceiling(widget.progress);
    if (_shown >= ceiling) return;
    setState(() {
      final step = widget.progress < 0.75 ? 0.012 : 0.02;
      _shown = math.min(ceiling, _shown + step);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LinearProgressIndicator(
      value: widget.progress <= 0 ? null : _shown.clamp(0.0, 1.0).toDouble(),
      minHeight: 6,
      backgroundColor: colors.scrim.withValues(alpha: 0.45),
      color: colors.primary,
      borderRadius: BorderRadius.zero,
    );
  }
}

class _CompressionFailedBar extends StatelessWidget {
  const _CompressionFailedBar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.errorContainer.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          'Failed',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}

class _DragIndicator extends StatelessWidget {
  const _DragIndicator();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: FaIcon(
            FontAwesomeIcons.gripVertical,
            size: 12,
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.extent, required this.onPressed});

  final double extent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: extent,
      height: extent,
      child: Material(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Icon(Icons.add, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text('$index', style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}
