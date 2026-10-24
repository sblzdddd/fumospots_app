import 'package:json_annotation/json_annotation.dart';

part 'post_model.g.dart';

enum PostSortOrder {
  asc,
  desc;

  String get apiValue => name;
}

@JsonSerializable()
class PostListItem {
  const PostListItem({
    required this.id,
    required this.title,
    required this.thumbUrl,
    required this.placeName,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? thumbUrl;
  final String? placeName;
  final String? createdAt;

  factory PostListItem.fromJson(Map<String, dynamic> json) =>
      _$PostListItemFromJson(json);

  Map<String, dynamic> toJson() => _$PostListItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PostsPage {
  const PostsPage({
    required this.postCount,
    required this.nextOffset,
    required this.items,
  });

  final int postCount;
  final int? nextOffset;
  final List<PostListItem> items;

  factory PostsPage.fromJson(Map<String, dynamic> json) =>
      _$PostsPageFromJson(json);

  Map<String, dynamic> toJson() => _$PostsPageToJson(this);
}

@JsonSerializable()
class PostPhoto {
  const PostPhoto({required this.imageUrl, required this.thumbUrl});

  final String? imageUrl;
  final String? thumbUrl;

  String? get viewerUrl => imageUrl ?? thumbUrl;

  factory PostPhoto.fromJson(Map<String, dynamic> json) =>
      _$PostPhotoFromJson(json);

  Map<String, dynamic> toJson() => _$PostPhotoToJson(this);
}

@JsonSerializable()
class PostCharacter {
  const PostCharacter({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameZh,
    required this.nameJa,
  });

  final int id;
  final String slug;
  final String nameEn;
  final String? nameZh;
  final String? nameJa;

  factory PostCharacter.fromJson(Map<String, dynamic> json) =>
      _$PostCharacterFromJson(json);

  Map<String, dynamic> toJson() => _$PostCharacterToJson(this);
}

@JsonSerializable()
class PostAuthor {
  const PostAuthor({required this.username, required this.avatarUrl});

  final String username;
  final String? avatarUrl;

  factory PostAuthor.fromJson(Map<String, dynamic> json) =>
      _$PostAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$PostAuthorToJson(this);
}

@JsonSerializable()
class PostLatLng {
  const PostLatLng({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory PostLatLng.fromJson(Map<String, dynamic> json) =>
      _$PostLatLngFromJson(json);

  Map<String, dynamic> toJson() => _$PostLatLngToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PostDetail {
  const PostDetail({
    required this.id,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.thumbUrl,
    required this.photos,
    required this.likeCount,
    required this.likedByViewer,
    required this.placeName,
    required this.countryName,
    required this.regionName,
    required this.cityName,
    required this.publicLocation,
    required this.privacyMode,
    required this.capturedAt,
    required this.createdAt,
    required this.characters,
    required this.author,
  });

  final int id;
  final String title;
  final String? body;
  final String? imageUrl;
  final String? thumbUrl;
  final List<PostPhoto> photos;
  final int likeCount;
  final bool likedByViewer;
  final String? placeName;
  final String? countryName;
  final String? regionName;
  final String? cityName;
  final PostLatLng? publicLocation;
  final String privacyMode;
  final String? capturedAt;
  final String? createdAt;
  final List<PostCharacter> characters;
  final PostAuthor author;

  factory PostDetail.fromJson(Map<String, dynamic> json) =>
      _$PostDetailFromJson(json);

  Map<String, dynamic> toJson() => _$PostDetailToJson(this);

  PostDetail copyWith({
    int? likeCount,
    bool? likedByViewer,
  }) {
    return PostDetail(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      thumbUrl: thumbUrl,
      photos: photos,
      likeCount: likeCount ?? this.likeCount,
      likedByViewer: likedByViewer ?? this.likedByViewer,
      placeName: placeName,
      countryName: countryName,
      regionName: regionName,
      cityName: cityName,
      publicLocation: publicLocation,
      privacyMode: privacyMode,
      capturedAt: capturedAt,
      createdAt: createdAt,
      characters: characters,
      author: author,
    );
  }
}

class PostLikeResult {
  const PostLikeResult({
    required this.postId,
    required this.likeCount,
    required this.likedByViewer,
  });

  final int postId;
  final int likeCount;
  final bool likedByViewer;

  factory PostLikeResult.fromJson(Map<String, dynamic> json) {
    return PostLikeResult(
      postId: (json['postId'] as num).toInt(),
      likeCount: (json['likeCount'] as num).toInt(),
      likedByViewer: json['likedByViewer'] as bool,
    );
  }
}
