

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fumospots_app/features/auth/auth_model.dart';

void main() {
  const jsonString = '''{
    "userId": "3-c",
    "email": "sblzd@example.com",
    "profile": {
      "id": "3-c",
      "username": "example",
      "avatarUrl": null,
      "role": "admin",
      "createdAt": "2026-10-10T22:38:37.962656+00:00",
      "updatedAt": "2026-10-10T22:38:48.288042+00:00"
    }
  }''';
  final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
  group('CurrentUser JSON Serialization', () {

    test('should successfully deserialize', () {
      final result = CurrentUser.fromJson(jsonMap);

      expect(result.userId, equals('3-c'));
      expect(result.email, equals('sblzd@example.com'));
      expect(result.profile.id, equals('3-c'));
      expect(result.profile.username, equals('example'));
      expect(result.profile.avatarUrl, isNull);
      expect(result.profile.role, equals('admin'));
      expect(
        result.profile.createdAt,
        DateTime.utc(2026, 10, 10, 22, 38, 37, 962, 656),
      );
      expect(
        result.profile.updatedAt,
        DateTime.utc(2026, 10, 10, 22, 38, 48, 288, 42),
      );
    });

    test('should successfully serialize', () {
      final user = CurrentUser.fromJson(jsonMap);
      final result = user.toJson();
      final profile = result['profile'] as Map<String, dynamic>;
      final original = jsonMap['profile'] as Map<String, dynamic>;
      expect(result['userId'], jsonMap['userId']);
      expect(result['email'], jsonMap['email']);
      expect(profile['id'], original['id']);
      expect(profile['username'], original['username']);
      expect(profile['avatarUrl'], isNull);
      expect(profile['role'], 'admin');
      expect(
        DateTime.parse(profile['createdAt'] as String),
        DateTime.parse(original['createdAt'] as String),
      );
      expect(
        DateTime.parse(profile['updatedAt'] as String),
        DateTime.parse(original['updatedAt'] as String),
      );
    });
  });
}
