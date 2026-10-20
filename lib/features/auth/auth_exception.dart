import '../../core/services/fumo_client_error.dart';

class AuthException extends FumoClientError {
  const AuthException(super.message, {super.statusCode});
}
