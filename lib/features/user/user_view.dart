import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';

class UserView extends StatelessWidget {
  const UserView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = GetIt.instance<AuthController>();
    final barHeight = BottomBarScope.maybeOf(context)?.barHeight;

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final username = auth.user?.profile.username;
        final email = auth.user?.email;

        Widget list(double bottomPadding) {
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: FaIcon(
                    username == null
                        ? FontAwesomeIcons.user
                        : FontAwesomeIcons.solidUser,
                    size: 18,
                  ),
                ),
                title: Text(username == null ? 'Not signed in' : '@$username'),
                subtitle: email == null ? null : Text(email),
              ),
            ],
          );
        }

        if (barHeight == null) {
          return list(MediaQuery.paddingOf(context).bottom + 16);
        }
        return ValueListenableBuilder<double>(
          valueListenable: barHeight,
          builder: (context, value, _) => list(value + 16),
        );
      },
    );
  }
}
