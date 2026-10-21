import '../../core/services/fumo_client.dart';
import '../../utils/json_converter.dart';
import 'post_model.dart';

class PostRepository {
  PostRepository({required FumoClient client}) : _client = client;

  static const _pageSize = 24;

  final FumoClient _client;
  final Map<int, PostDetail> _detailCache = {};

  Future<PostsPage> fetchPostsPage(int offset, PostSortOrder sort) async {
    final response = await _client.get(
      '/api/posts',
      queryParameters: {
        'limit': _pageSize,
        'sort': sort.apiValue,
        if (offset > 0) 'offset': offset,
      },
      fallback: 'Failed to load posts.',
    );
    return PostsPage.fromJson(toJsonMap(response.data));
  }

  PostDetail? peekDetail(int id) => _detailCache[id];

  Future<PostDetail> fetchDetail(int id) async {
    final cached = _detailCache[id];
    if (cached != null) {
      return cached;
    }

    final response = await _client.get(
      '/api/posts/$id',
      fallback: 'This post is unavailable.',
    );
    final detail = PostDetail.fromJson(toJsonMap(response.data));
    _detailCache[id] = detail;
    return detail;
  }
}
