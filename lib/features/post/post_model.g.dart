// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostListItem _$PostListItemFromJson(Map<String, dynamic> json) => PostListItem(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  thumbUrl: json['thumbUrl'] as String?,
  placeName: json['placeName'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$PostListItemToJson(PostListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'thumbUrl': instance.thumbUrl,
      'placeName': instance.placeName,
      'createdAt': instance.createdAt,
    };

PostsPage _$PostsPageFromJson(Map<String, dynamic> json) => PostsPage(
  postCount: (json['postCount'] as num).toInt(),
  nextOffset: (json['nextOffset'] as num?)?.toInt(),
  items: (json['items'] as List<dynamic>)
      .map((e) => PostListItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PostsPageToJson(PostsPage instance) => <String, dynamic>{
  'postCount': instance.postCount,
  'nextOffset': instance.nextOffset,
  'items': instance.items.map((e) => e.toJson()).toList(),
};

PostPhoto _$PostPhotoFromJson(Map<String, dynamic> json) => PostPhoto(
  imageUrl: json['imageUrl'] as String?,
  thumbUrl: json['thumbUrl'] as String?,
);

Map<String, dynamic> _$PostPhotoToJson(PostPhoto instance) => <String, dynamic>{
  'imageUrl': instance.imageUrl,
  'thumbUrl': instance.thumbUrl,
};

PostCharacter _$PostCharacterFromJson(Map<String, dynamic> json) =>
    PostCharacter(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String,
      nameEn: json['nameEn'] as String,
      nameZh: json['nameZh'] as String?,
      nameJa: json['nameJa'] as String?,
    );

Map<String, dynamic> _$PostCharacterToJson(PostCharacter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'nameEn': instance.nameEn,
      'nameZh': instance.nameZh,
      'nameJa': instance.nameJa,
    };

PostAuthor _$PostAuthorFromJson(Map<String, dynamic> json) => PostAuthor(
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$PostAuthorToJson(PostAuthor instance) =>
    <String, dynamic>{
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
    };

PostLatLng _$PostLatLngFromJson(Map<String, dynamic> json) => PostLatLng(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
);

Map<String, dynamic> _$PostLatLngToJson(PostLatLng instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};

PostDetail _$PostDetailFromJson(Map<String, dynamic> json) => PostDetail(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  body: json['body'] as String?,
  imageUrl: json['imageUrl'] as String?,
  thumbUrl: json['thumbUrl'] as String?,
  photos: (json['photos'] as List<dynamic>)
      .map((e) => PostPhoto.fromJson(e as Map<String, dynamic>))
      .toList(),
  likeCount: (json['likeCount'] as num).toInt(),
  likedByViewer: json['likedByViewer'] as bool,
  placeName: json['placeName'] as String?,
  countryName: json['countryName'] as String?,
  regionName: json['regionName'] as String?,
  cityName: json['cityName'] as String?,
  publicLocation: json['publicLocation'] == null
      ? null
      : PostLatLng.fromJson(json['publicLocation'] as Map<String, dynamic>),
  privacyMode: json['privacyMode'] as String,
  capturedAt: json['capturedAt'] as String?,
  createdAt: json['createdAt'] as String?,
  characters: (json['characters'] as List<dynamic>)
      .map((e) => PostCharacter.fromJson(e as Map<String, dynamic>))
      .toList(),
  author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostDetailToJson(PostDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'imageUrl': instance.imageUrl,
      'thumbUrl': instance.thumbUrl,
      'photos': instance.photos.map((e) => e.toJson()).toList(),
      'likeCount': instance.likeCount,
      'likedByViewer': instance.likedByViewer,
      'placeName': instance.placeName,
      'countryName': instance.countryName,
      'regionName': instance.regionName,
      'cityName': instance.cityName,
      'publicLocation': instance.publicLocation?.toJson(),
      'privacyMode': instance.privacyMode,
      'capturedAt': instance.capturedAt,
      'createdAt': instance.createdAt,
      'characters': instance.characters.map((e) => e.toJson()).toList(),
      'author': instance.author.toJson(),
    };
