import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/i18n/keys.dart';
import '../../core/services/fumo_client_error.dart';
import '../auth/auth_controller.dart';
import 'user_model.dart';
import 'user_repository.dart';

class UserController extends ChangeNotifier {
  UserController({
    UserRepository? repository,
    AuthController? auth,
  }) : _repository = repository ?? GetIt.instance<UserRepository>(),
       _auth = auth ?? GetIt.instance<AuthController>();

  final UserRepository _repository;
  final AuthController _auth;

  PublicUserPage? page;
  bool loading = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;
  String? _loadedUsername;

  bool get showingSkeletons => loading && page == null && error == null;

  List<UserPostSummary> get posts => page?.posts ?? const [];

  int get totalLikeCount => page?.totalLikeCount ?? 0;

  Future<void> loadForSignedInUser() {
    final username = _auth.user?.profile.username;
    if (username == null || username.isEmpty) {
      _clear();
      return Future.value();
    }
    return _load(username);
  }

  Future<void> refresh() => loadForSignedInUser();

  Future<void> retry() => loadForSignedInUser();

  void clear() => _clear();

  Future<void> _load(String username) async {
    final request = ++_generation;
    loading = true;
    error = null;
    if (_loadedUsername != username) {
      page = null;
    }
    _notify();

    try {
      final next = await _repository.fetchUserPage(username);
      if (_disposed || request != _generation) {
        return;
      }
      page = next;
      _loadedUsername = username;
      error = null;
    } on FumoClientError catch (e) {
      if (_disposed || request != _generation) {
        return;
      }
      error = e.message;
      if (_loadedUsername != username) {
        page = null;
      }
    } catch (_) {
      if (_disposed || request != _generation) {
        return;
      }
      error = S.profilePostsFailed;
      if (_loadedUsername != username) {
        page = null;
      }
    } finally {
      if (!_disposed && request == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  void _clear() {
    _generation += 1;
    page = null;
    error = null;
    loading = false;
    _loadedUsername = null;
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
