import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_client_error.dart';
import 'post_model.dart';
import 'post_repository.dart';

class PostDetailController extends ChangeNotifier {
  PostDetailController({PostRepository? repository})
    : _repository = repository ?? GetIt.instance<PostRepository>();

  final PostRepository _repository;

  PostDetail? detail;
  bool loading = false;
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
      error = 'This post is unavailable.';
      loading = false;
      _notify();
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
