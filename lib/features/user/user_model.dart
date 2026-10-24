import 'package:json_annotation/json_annotation.dart';

import '../../core/i18n/keys.dart';
import '../post/post_model.dart';

part 'user_model.g.dart';

enum PostStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

@JsonSerializable()
class UserPageProfile {
  const UserPageProfile({
    required this.id,
    required this.username,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;

  factory UserPageProfile.fromJson(Map<String, dynamic> json) =>
      _$UserPageProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserPageProfileToJson(this);
}

@JsonSerializable()
class UserPostSummary {
  const UserPostSummary({
    required this.id,
    required this.title,
    required this.body,
    required this.thumbUrl,
    required this.placeName,
    required this.status,
    required this.hasPendingRevision,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? body;
  final String? thumbUrl;
  final String? placeName;
  final PostStatus status;
  final bool hasPendingRevision;
  final String? capturedAt;
  final String? createdAt;
  final String? updatedAt;

  PostListItem toListItem() => PostListItem(
    id: id,
    title: title,
    thumbUrl: thumbUrl,
    placeName: placeName,
    createdAt: createdAt,
  );

  String get statusLabel {
    if (hasPendingRevision) {
      return S.statusEditPending;
    }
    return switch (status) {
      PostStatus.pending => S.statusPending,
      PostStatus.approved => S.statusApproved,
      PostStatus.rejected => S.statusRejected,
    };
  }

  factory UserPostSummary.fromJson(Map<String, dynamic> json) =>
      _$UserPostSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$UserPostSummaryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PublicUserPage {
  const PublicUserPage({
    required this.profile,
    required this.isSelf,
    required this.totalLikeCount,
    required this.posts,
  });

  final UserPageProfile profile;
  final bool isSelf;
  final int totalLikeCount;
  final List<UserPostSummary> posts;

  factory PublicUserPage.fromJson(Map<String, dynamic> json) =>
      _$PublicUserPageFromJson(json);

  Map<String, dynamic> toJson() => _$PublicUserPageToJson(this);
}
