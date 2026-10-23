import '../../core/services/fumo_client.dart';
import '../../utils/json_converter.dart';
import 'user_model.dart';

class UserRepository {
  UserRepository({required this._client});

  final FumoClient _client;

  Future<PublicUserPage> fetchUserPage(String username) async {
    final response = await _client.get(
      '/api/users/${Uri.encodeComponent(username)}',
      fallback: 'Failed to load profile posts.',
    );
    return PublicUserPage.fromJson(toJsonMap(response.data));
  }
}
