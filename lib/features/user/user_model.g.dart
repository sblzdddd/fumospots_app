// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPageProfile _$UserPageProfileFromJson(Map<String, dynamic> json) =>
    UserPageProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$UserPageProfileToJson(UserPageProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
    };

UserPostSummary _$UserPostSummaryFromJson(Map<String, dynamic> json) =>
    UserPostSummary(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      body: json['body'] as String?,
      thumbUrl: json['thumbUrl'] as String?,
      placeName: json['placeName'] as String?,
      status: $enumDecode(_$PostStatusEnumMap, json['status']),
      hasPendingRevision: json['hasPendingRevision'] as bool,
      capturedAt: json['capturedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$UserPostSummaryToJson(UserPostSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'thumbUrl': instance.thumbUrl,
      'placeName': instance.placeName,
      'status': _$PostStatusEnumMap[instance.status]!,
      'hasPendingRevision': instance.hasPendingRevision,
      'capturedAt': instance.capturedAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$PostStatusEnumMap = {
  PostStatus.pending: 'pending',
  PostStatus.approved: 'approved',
  PostStatus.rejected: 'rejected',
};

PublicUserPage _$PublicUserPageFromJson(Map<String, dynamic> json) =>
    PublicUserPage(
      profile: UserPageProfile.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
      isSelf: json['isSelf'] as bool,
      totalLikeCount: (json['totalLikeCount'] as num).toInt(),
      posts: (json['posts'] as List<dynamic>)
          .map((e) => UserPostSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PublicUserPageToJson(PublicUserPage instance) =>
    <String, dynamic>{
      'profile': instance.profile.toJson(),
      'isSelf': instance.isSelf,
      'totalLikeCount': instance.totalLikeCount,
      'posts': instance.posts.map((e) => e.toJson()).toList(),
    };
