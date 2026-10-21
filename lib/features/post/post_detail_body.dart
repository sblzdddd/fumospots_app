import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'post_format.dart';
import 'post_model.dart';

class PostDetailBody extends StatelessWidget {
  const PostDetailBody({super.key, required this.detail, required this.locale});

  final PostDetail detail;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final muted = colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  detail.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _LikeChip(count: detail.likeCount, liked: detail.likedByViewer),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          _IconRow(
            icon: FontAwesomeIcons.user,
            child: Text(
              '@${detail.author.username}',
              style: bodyStyle?.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _IconRow(
            icon: FontAwesomeIcons.locationDot,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SubLocations(detail: detail),
                Text(detail.placeName ?? 'Unnamed place', style: bodyStyle),
              ],
            ),
          ),
          if (detail.privacyMode == 'exact') ...[
            const SizedBox(height: 8),
            _IconRow(
              icon: FontAwesomeIcons.crosshairs,
              child: Text(
                formatLatLng(detail.publicLocation),
                style: bodyStyle?.copyWith(color: muted),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _IconRow(
            icon: FontAwesomeIcons.clock,
            child: Text(formatDateTime(detail.capturedAt, locale), style: bodyStyle),
          ),
          if (detail.body != null && detail.body!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'Author note',
              style: bodyStyle?.copyWith(
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(detail.body!, style: bodyStyle?.copyWith(height: 1.35)),
          ],
          if (detail.characters.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'Characters',
              style: bodyStyle?.copyWith(
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: detail.characters.map((character) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#',
                        style: bodyStyle?.copyWith(
                          color: colors.primary,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        characterName(character, locale),
                        style: bodyStyle?.copyWith(
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: colors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _LikeChip extends StatelessWidget {
  const _LikeChip({required this.count, required this.liked});

  final int count;
  final bool liked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            liked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
            size: 16,
            color: liked ? colors.error : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text('$count'),
        ],
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.child});

  final FaIconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FaIcon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _SubLocations extends StatelessWidget {
  const _SubLocations({required this.detail});

  final PostDetail detail;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (detail.countryName != null) detail.countryName!,
      if (detail.regionName != null) detail.regionName!,
      if (detail.cityName != null) detail.cityName!,
    ];
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      parts.join(' / '),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
