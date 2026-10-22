import 'dart:io';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import 'upload_controller.dart';
import 'upload_model.dart';
import 'upload_section.dart';

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
          'Photos',
          trailing: '${controller.photos.length}/$maxPostPhotos',
          required: true,
        ),
        const SizedBox(height: 8),
        _PhotoStrip(
          photos: controller.photos,
          enabled: !uploading && !controller.benchmarking,
          onAdd: controller.canAddPhoto ? controller.pickFromGallery : null,
          onRemove: controller.removePhoto,
          onMove: controller.movePhoto,
        ),
        const SizedBox(height: 8),
        UploadActionPair(
          first: UploadAction(
            label: 'Library',
            icon: FontAwesomeIcons.images,
            onPressed: canAdd ? controller.pickFromGallery : null,
          ),
          second: UploadAction(
            label: 'Camera',
            icon: FontAwesomeIcons.camera,
            onPressed: canAdd ? controller.pickFromCamera : null,
          ),
        ),
        const SizedBox(height: 8),
        M3EButton(
          onPressed:
              controller.photos.isEmpty || uploading || controller.benchmarking
              ? null
              : controller.benchmarkConversions,
          style: M3EButtonStyle.tonal,
          shape: M3EButtonShape.round,
          size: M3EButtonSize.sm,
          child: Text(controller.benchmarking ? 'Timing…' : 'Time conversion'),
        ),
        if (controller.benchmarkResult != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.benchmarkResult!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        if (controller.detectingExif) ...[
          const SizedBox(height: 8),
          Text(
            'Reading photo details…',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.photos,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
  });

  final List<UploadPhoto> photos;
  final bool enabled;
  final VoidCallback? onAdd;
  final ValueChanged<String> onRemove;
  final void Function(String id, int direction) onMove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + (onAdd == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == photos.length) {
            return _AddPhotoTile(onPressed: onAdd);
          }
          return _PhotoTile(
            photo: photos[index],
            index: index,
            count: photos.length,
            enabled: enabled,
            onRemove: onRemove,
            onMove: onMove,
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.index,
    required this.count,
    required this.enabled,
    required this.onRemove,
    required this.onMove,
  });

  final UploadPhoto photo;
  final int index;
  final int count;
  final bool enabled;
  final ValueChanged<String> onRemove;
  final void Function(String id, int direction) onMove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: colors.surfaceContainerHigh,
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.image_outlined,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _IndexBadge(index: index + 1),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: _PhotoIconButton(
                      tooltip: 'Remove photo',
                      icon: FontAwesomeIcons.xmark,
                      onPressed: enabled ? () => onRemove(photo.id) : null,
                    ),
                  ),
                  Positioned(
                    left: 4,
                    right: 4,
                    bottom: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PhotoIconButton(
                          tooltip: 'Move earlier',
                          icon: FontAwesomeIcons.arrowLeft,
                          onPressed: enabled && index > 0
                              ? () => onMove(photo.id, -1)
                              : null,
                        ),
                        _PhotoIconButton(
                          tooltip: 'Move later',
                          icon: FontAwesomeIcons.arrowRight,
                          onPressed: enabled && index < count - 1
                              ? () => onMove(photo.id, 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            photo.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 112,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Material(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Icon(Icons.add, color: colors.onSurfaceVariant),
          ),
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

class _PhotoIconButton extends StatelessWidget {
  const _PhotoIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final FaIconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return M3EButton(
      onPressed: onPressed,
      style: M3EButtonStyle.filled,
      shape: M3EButtonShape.round,
      size: M3EButtonSize.xs,
      tooltip: tooltip,
      semanticLabel: tooltip,
      child: FaIcon(icon, size: 12),
    );
  }
}
