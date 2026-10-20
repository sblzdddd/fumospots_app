

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

    test('should successfully deserialize from a JSON Map (fromJson)', () {
      final result = CurrentUser.fromJson(jsonMap);

      expect(result.userId, equals('3-c'));
      expect(result.email, equals('sblzd@example.com'));
      expect(result.profile.id, equals('3-c'));
      expect(result.profile.username, equals('example'));
      expect(result.profile.avatarUrl, isNull);
      expect(result.profile.role, equals('admin'));
      expect(result.profile.createdAt, DateTime(2026, 10, 10, 22, 38, 37));
      expect(result.profile.updatedAt, DateTime(2026, 10, 10, 22, 38, 48));
    });

    test('should successfully serialize to a JSON Map', () {
      final user = CurrentUser(
        userId: '3-c',
        email: 'sblzd@example.com',
        profile: AuthProfile(
          id: '3-c',
          username: 'example',
          avatarUrl: null,
          role: 'admin',
          createdAt: DateTime(2026, 10, 10, 22, 38, 37),
          updatedAt: DateTime(2026, 10, 10, 22, 38, 48),
        ),
      );
      final result = user.toJson();
      expect(result, equals(jsonMap));
    });
  });
}
