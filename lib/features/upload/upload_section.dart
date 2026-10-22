import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

class UploadSectionLabel extends StatelessWidget {
  const UploadSectionLabel(
    this.text, {
    super.key,
    this.trailing,
    this.required = false,
  });

  final String text;
  final String? trailing;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        if (required)
          Text(
            ' *',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: colors.primary),
          ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

class UploadAction {
  const UploadAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final FaIconData icon;
  final VoidCallback? onPressed;
}

class UploadActionPair extends StatelessWidget {
  const UploadActionPair({
    super.key,
    required this.first,
    required this.second,
  });

  final UploadAction first;
  final UploadAction second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 2) / 2;
        return M3EToggleButtonGroup(
          type: M3EButtonGroupType.connected,
          style: M3EButtonStyle.tonal,
          shape: M3EButtonShape.round,
          size: M3EButtonSize.sm,
          neighborSquish: false,
          overflow: M3EButtonGroupOverflow.none,
          selectedIndex: null,
          onSelectedIndexChanged: (index) {
            if (index == 0) first.onPressed?.call();
            if (index == 1) second.onPressed?.call();
          },
          actions: [_action(first, width), _action(second, width)],
        );
      },
    );
  }

  M3EToggleButtonGroupAction _action(UploadAction action, double width) {
    return M3EToggleButtonGroupAction(
      width: width,
      enabled: action.onPressed != null,
      icon: FaIcon(action.icon, size: 14),
      label: Text(action.label),
      semanticLabel: action.label,
    );
  }
}
