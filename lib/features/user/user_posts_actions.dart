import 'package:material_ui/material_ui.dart';

import '../post/detail/post_detail_sheet.dart';
import '../post/post_model.dart';
import '../upload/upload_view.dart';
import 'user_model.dart';

Future<void> openUserPost(
  BuildContext context,
  UserPostSummary post, {
  ValueChanged<PostLatLng>? onShowInMap,
  VoidCallback? onCharacterSelected,
}) async {
  if (post.status == PostStatus.approved) {
    await showPostDetailSheet(
      context,
      post.id,
      onShowInMap: onShowInMap,
      onCharacterSelected: onCharacterSelected,
    );
    return;
  }
  await editUserPost(context, post);
}

/// Opens [UploadView] in edit mode for [post].
///
/// Returns a success message when the edit was saved.
Future<String?> editUserPost(BuildContext context, UserPostSummary post) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => UploadView(editPostId: post.id),
    ),
  );
}
