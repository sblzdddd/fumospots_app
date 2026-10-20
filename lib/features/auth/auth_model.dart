import 'package:json_annotation/json_annotation.dart';
import '../../utils/json_datetime_converter.dart';
part 'auth_model.g.dart';


@JsonSerializable()
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'expires_at')
  final int expiresAt;  // as unix seconds

  factory AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);
  Map<String, dynamic> toJson() => _$AuthSessionToJson(this);
}

@JsonSerializable()
class AuthProfile {
  const AuthProfile({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? username;
  final String? avatarUrl;
  final String? role;
  @DateTimeConverter()
  final DateTime? createdAt;
  @DateTimeConverter()
  final DateTime? updatedAt;

  factory AuthProfile.fromJson(Map<String, dynamic> json) => _$AuthProfileFromJson(json);
  Map<String, dynamic> toJson() => _$AuthProfileToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CurrentViewer {
  const CurrentViewer({
    required this.userId,
    required this.email,
    required this.profile,
  });

  final String userId;
  final String email;
  final AuthProfile profile;

  factory CurrentViewer.fromJson(Map<String, dynamic> json) => _$CurrentViewerFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentViewerToJson(this);
}

@JsonSerializable()
class ProfileSetupRequest {
  const ProfileSetupRequest({
    required this.username,
  });

  final String username;

  factory ProfileSetupRequest.fromJson(Map<String, dynamic> json) => _$ProfileSetupRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileSetupRequestToJson(this);
}