import 'package:material_ui/material_ui.dart';

import '../../../core/i18n/i18n.dart';
import '../auth_flow.dart';

class AuthLoginNotice extends StatelessWidget {
  const AuthLoginNotice({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isError
        ? colors.errorContainer
        : colors.primaryContainer;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.t(
          message,
          params: {'count': '$authMinPasswordLength'},
        ),
        style: TextStyle(color: foreground),
      ),
    );
  }
}
