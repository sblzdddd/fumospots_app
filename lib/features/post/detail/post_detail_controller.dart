import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../core/i18n/keys.dart';
import '../../../core/services/fumo_client_error.dart';
import '../../auth/auth_controller.dart';
import '../post_model.dart';
import '../post_repository.dart';

class PostDetailController extends ChangeNotifier {
  PostDetailController({
    PostRepository? repository,
    AuthController? auth,
  }) : _repository = repository ?? GetIt.instance<PostRepository>(),
       _auth = auth ?? GetIt.instance<AuthController>();

  final PostRepository _repository;
  final AuthController _auth;

  PostDetail? detail;
  bool loading = false;
  bool liking = false;
  String? error;
  int photoIndex = 0;

  int? _postId;
  bool _disposed = false;

  Future<void> open(int postId) async {
    if (_postId == postId && (detail != null || loading)) {
      return;
    }

    _postId = postId;
    final cached = _repository.peekDetail(postId);
    detail = cached;
    loading = cached == null;
    liking = false;
    error = null;
    photoIndex = 0;
    _notify();

    if (cached != null) {
      return;
    }

    try {
      final next = await _repository.fetchDetail(postId);
      if (_postId != postId) {
        return;
      }
      detail = next;
      loading = false;
      _notify();
    } on FumoClientError catch (e) {
      if (_postId != postId) {
        return;
      }
      error = e.message;
      loading = false;
      _notify();
    } catch (_) {
      if (_postId != postId) {
        return;
      }
      error = S.postUnavailable;
      loading = false;
      _notify();
    }
  }

  /// Returns an error/notice message, or null on success.
  Future<String?> toggleLike() async {
    final current = detail;
    if (current == null || liking) {
      return null;
    }

    await _auth.init();
    if (!_auth.isSignedIn) {
      return S.signInToLike;
    }

    liking = true;
    _notify();

    try {
      final result = await _repository.setLiked(
        current.id,
        liked: !current.likedByViewer,
      );
      if (_postId != current.id) {
        return null;
      }
      detail = current.copyWith(
        likeCount: result.likeCount,
        likedByViewer: result.likedByViewer,
      );
      liking = false;
      _notify();
      return null;
    } on FumoClientError catch (e) {
      if (_postId != current.id) {
        return null;
      }
      liking = false;
      _notify();
      return e.message;
    } catch (_) {
      if (_postId != current.id) {
        return null;
      }
      liking = false;
      _notify();
      return S.likeUpdateFailed;
    }
  }

  void setPhotoIndex(int index) {
    if (photoIndex == index) {
      return;
    }
    photoIndex = index;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
