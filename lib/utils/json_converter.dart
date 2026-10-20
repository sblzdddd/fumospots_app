import 'package:json_annotation/json_annotation.dart';
import '../core/services/fumo_client_error.dart';

class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    return object.toIso8601String();
  }
}


Map<String, dynamic> toJsonMap(Object? data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return data.map((key, value) => MapEntry('$key', value));
  }
  throw const FumoClientError('Unexpected response.');
}