import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/services/image_cache_service.dart';

/// Long-press action sheet: share the image file or copy its URL.
Future<void> showPostPhotoShareSheet(
  BuildContext context, {
  required String imageUrl,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.shareNodes),
              title: Text(sheetContext.t(S.sharePhoto)),
              onTap: () => _sharePhoto(sheetContext, imageUrl),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.link),
              title: Text(sheetContext.t(S.copyImageLink)),
              onTap: () => _copyLink(sheetContext, imageUrl),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.arrowUpFromBracket),
              title: Text(sheetContext.t(S.shareImageLink)),
              onTap: () => _shareLink(sheetContext, imageUrl),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _sharePhoto(BuildContext context, String imageUrl) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failed = context.t(S.shareFailed);
  final nav = Navigator.of(context);
  nav.pop();

  try {
    final file = await GetIt.instance<ImageCacheService>().cacheManager
        .getSingleFile(imageUrl);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }
}

Future<void> _copyLink(BuildContext context, String imageUrl) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final copied = context.t(S.linkCopied);
  Navigator.of(context).pop();
  await Clipboard.setData(ClipboardData(text: imageUrl));
  messenger?.showSnackBar(SnackBar(content: Text(copied)));
}

Future<void> _shareLink(BuildContext context, String imageUrl) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failed = context.t(S.shareFailed);
  Navigator.of(context).pop();
  try {
    await SharePlus.instance.share(ShareParams(uri: Uri.parse(imageUrl)));
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }
}
