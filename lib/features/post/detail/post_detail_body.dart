import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/i18n/i18n.dart';
import '../../character/filter/character_filter_controller.dart';
import '../post_format.dart';
import '../post_model.dart';

class PostDetailBody extends StatelessWidget {
  const PostDetailBody({
    super.key,
    required this.detail,
    required this.locale,
    this.liking = false,
    this.onLike,
  });

  final PostDetail detail;
  final String locale;
  final bool liking;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final muted = colors.onSurfaceVariant;
    final liked = detail.likedByViewer;
    final likeLabel = liked ? 'Unlike' : 'Like';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  detail.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              M3EButton.icon(
                onPressed: liking ? null : onLike,
                style: liked ? M3EButtonStyle.filled : M3EButtonStyle.tonal,
                shape: M3EButtonShape.round,
                size: M3EButtonSize.sm,
                tooltip: likeLabel,
                semanticLabel: likeLabel,
                icon: liking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FaIcon(
                        liked
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        size: 16,
                      ),
                label: Text('${detail.likeCount}'),
              ),
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
                Text(
                  detail.placeName ?? context.t(S.unnamedPlace),
                  style: bodyStyle,
                ),
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
              context.t(S.authorNote),
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
              context.t(S.characters),
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
              children: [
                for (final character in detail.characters)
                  M3EButton(
                    onPressed: () {
                      GetIt.instance<CharacterFilterController>()
                          .setSelectedIds([character.id]);
                      Navigator.of(context).maybePop();
                    },
                    style: M3EButtonStyle.tonal,
                    shape: M3EButtonShape.round,
                    size: M3EButtonSize.sm,
                    child: Text(characterName(character, locale)),
                  ),
              ],
            ),
          ],
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
