import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';

import '../auth/auth_controller.dart';

class UserView extends StatelessWidget {
  const UserView({super.key, required this.contentInsetTop});

  final double contentInsetTop;

  @override
  Widget build(BuildContext context) {
    final auth = GetIt.instance<AuthController>();
    final bottomInset = MediaQuery.paddingOf(context).bottom + 88;

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final username = auth.user?.profile.username;
        final email = auth.user?.email;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            contentInsetTop + 16,
            16,
            bottomInset,
          ),
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
      },
    );
  }
}
