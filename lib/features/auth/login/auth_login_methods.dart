import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/i18n/i18n.dart';
import 'auth_login_mode.dart';

final authWideButtonDecoration = M3EButtonDecoration.styleFrom(
  minimumSize: const Size(double.infinity, 48),
);

class FullWidthToggleGroup extends StatelessWidget {
  const FullWidthToggleGroup({
    super.key,
    required this.actions,
    this.selectedIndex,
    this.onSelectedIndexChanged,
    this.trailingExtent,
    this.size = M3EButtonSize.sm,
    this.gap = 2.0,
  });

  final List<M3EToggleButtonGroupAction> Function(double first, double second)
  actions;
  final int? selectedIndex;
  final ValueChanged<int?>? onSelectedIndexChanged;

  /// Width of the second button. When omitted, both buttons share the row.
  final double? trailingExtent;
  final M3EButtonSize size;
  static const iconExtent = 64.0;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final trailing = trailingExtent ?? iconExtent;
        final double first;
        final double second;
        if (!maxWidth.isFinite) {
          first = double.infinity;
          second = trailingExtent ?? first;
        } else if (trailingExtent == null) {
          first = (maxWidth - gap) / 2;
          second = first;
        } else {
          second = trailing;
          first = (maxWidth - gap - second).clamp(0, maxWidth);
        }
        return M3EToggleButtonGroup(
          type: M3EButtonGroupType.connected,
          style: M3EButtonStyle.tonal,
          shape: M3EButtonShape.round,
          size: size,
          neighborSquish: false,
          overflow: M3EButtonGroupOverflow.none,
          selectedIndex: selectedIndex,
          onSelectedIndexChanged: onSelectedIndexChanged,
          actions: actions(first, second),
        );
      },
    );
  }
}

class AuthLoginMethods extends StatelessWidget {
  const AuthLoginMethods({
    super.key,
    required this.section,
    required this.methodIndex,
    required this.busy,
    required this.onSectionChanged,
    required this.onMethodChanged,
    required this.onOAuth,
  });

  final AuthLoginSection section;
  final int? methodIndex;
  final bool busy;
  final ValueChanged<AuthLoginSection> onSectionChanged;
  final ValueChanged<int?> onMethodChanged;
  final ValueChanged<AuthOAuthOption> onOAuth;

  @override
  Widget build(BuildContext context) {
    final registering = section == AuthLoginSection.register;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FullWidthToggleGroup(
          selectedIndex: registering ? 1 : 0,
          onSelectedIndexChanged: (index) {
            if (busy || index == null) {
              return;
            }
            onSectionChanged(
              index == 0 ? AuthLoginSection.login : AuthLoginSection.register,
            );
          },
          actions: (first, second) => [
            M3EToggleButtonGroupAction(
              width: first,
              enabled: !busy,
              icon: const FaIcon(FontAwesomeIcons.rightToBracket, size: 14),
              label: Text(context.t(S.logIn)),
            ),
            M3EToggleButtonGroupAction(
              width: second,
              enabled: !busy,
              icon: const FaIcon(FontAwesomeIcons.userPlus, size: 14),
              label: Text(context.t(S.register)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final option in authOAuthOptions) ...[
          M3EButton.icon(
            onPressed: busy ? null : () => onOAuth(option),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            decoration: authWideButtonDecoration,
            icon: FaIcon(option.icon, size: 16),
            label: Text(
              context.t(
                registering ? option.registerLabelKey : option.loginLabelKey,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        FullWidthToggleGroup(
          selectedIndex: methodIndex,
          onSelectedIndexChanged: onMethodChanged,
          actions: (first, second) => [
            M3EToggleButtonGroupAction(
              width: first,
              enabled: !busy,
              icon: const FaIcon(FontAwesomeIcons.envelope, size: 14),
              label: Text(context.t(S.email)),
            ),
            M3EToggleButtonGroupAction(
              width: second,
              enabled: !busy,
              icon: const FaIcon(FontAwesomeIcons.key, size: 14),
              label: Text(context.t(S.password)),
            ),
          ],
        ),
      ],
    );
  }
}
