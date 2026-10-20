// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => AuthSession(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresAt: (json['expires_at'] as num).toInt(),
);

Map<String, dynamic> _$AuthSessionToJson(AuthSession instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expires_at': instance.expiresAt,
    };

AuthProfile _$AuthProfileFromJson(Map<String, dynamic> json) => AuthProfile(
  id: json['id'] as String,
  username: json['username'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  role: json['role'] as String?,
  createdAt: _$JsonConverterFromJson<String, DateTime>(
    json['createdAt'],
    const DateTimeConverter().fromJson,
  ),
  updatedAt: _$JsonConverterFromJson<String, DateTime>(
    json['updatedAt'],
    const DateTimeConverter().fromJson,
  ),
);

Map<String, dynamic> _$AuthProfileToJson(AuthProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'role': instance.role,
      'createdAt': _$JsonConverterToJson<String, DateTime>(
        instance.createdAt,
        const DateTimeConverter().toJson,
      ),
      'updatedAt': _$JsonConverterToJson<String, DateTime>(
        instance.updatedAt,
        const DateTimeConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

CurrentViewer _$CurrentViewerFromJson(Map<String, dynamic> json) =>
    CurrentViewer(
      userId: json['userId'] as String,
      email: json['email'] as String,
      profile: AuthProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CurrentViewerToJson(CurrentViewer instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'profile': instance.profile.toJson(),
    };

ProfileSetupRequest _$ProfileSetupRequestFromJson(Map<String, dynamic> json) =>
    ProfileSetupRequest(username: json['username'] as String);

Map<String, dynamic> _$ProfileSetupRequestToJson(
  ProfileSetupRequest instance,
) => <String, dynamic>{'username': instance.username};
