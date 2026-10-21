import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../post/post_feed_controller.dart';
import '../post/post_model.dart';
import 'home_view.dart';

Future<void> showViewSettingsSheet(
  BuildContext context, {
  required HomeView homeView,
  required ValueChanged<HomeView> onHomeViewChange,
}) {
  return showM3EModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Return M3EBottomSheet directly so showM3EModalBottomSheet does not wrap again.
    builder: (context) => M3EBottomSheet(
      showDragHandle: true,
      title: Text(
        'View settings',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: ViewSettingsSheet(
        homeView: homeView,
        onHomeViewChange: onHomeViewChange,
      ),
    ),
  );
}

class ViewSettingsSheet extends StatelessWidget {
  const ViewSettingsSheet({
    super.key,
    required this.homeView,
    required this.onHomeViewChange,
  });

  final HomeView homeView;
  final ValueChanged<HomeView> onHomeViewChange;

  @override
  Widget build(BuildContext context) {
    final feed = GetIt.instance<PostFeedController>();

    return ListenableBuilder(
      listenable: feed,
      builder: (context, _) {
        final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sort', style: labelStyle),
                  M3EToggleButtonGroup(
                    type: M3EButtonGroupType.connected,
                    style: M3EButtonStyle.tonal,
                    shape: M3EButtonShape.round,
                    size: M3EButtonSize.sm,
                    selectedIndex: feed.sortOrder == PostSortOrder.desc ? 0 : 1,
                    onSelectedIndexChanged: (index) {
                      final current =
                          feed.sortOrder == PostSortOrder.desc ? 0 : 1;
                      if (index == null || index == current) {
                        return;
                      }
                      feed.load(
                        sort: index == 0
                            ? PostSortOrder.desc
                            : PostSortOrder.asc,
                      );
                      Navigator.of(context).pop();
                    },
                    actions: const [
                      M3EToggleButtonGroupAction(
                        label: Text('Newest'),
                        icon: FaIcon(
                          FontAwesomeIcons.arrowDownWideShort,
                          size: 14,
                        ),
                      ),
                      M3EToggleButtonGroupAction(
                        label: Text('Oldest'),
                        icon: FaIcon(
                          FontAwesomeIcons.arrowUpWideShort,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('View', style: labelStyle),
                  M3EToggleButtonGroup(
                    type: M3EButtonGroupType.connected,
                    style: M3EButtonStyle.tonal,
                    shape: M3EButtonShape.round,
                    size: M3EButtonSize.sm,
                    selectedIndex: homeView == HomeView.waterfall ? 0 : 1,
                    onSelectedIndexChanged: (index) {
                      final current = homeView == HomeView.waterfall ? 0 : 1;
                      if (index == null || index == current) {
                        return;
                      }
                      onHomeViewChange(
                        index == 0 ? HomeView.waterfall : HomeView.map,
                      );
                      Navigator.of(context).pop();
                    },
                    actions: const [
                      M3EToggleButtonGroupAction(
                        label: Text('Waterfall'),
                        icon: FaIcon(FontAwesomeIcons.grip, size: 14),
                      ),
                      M3EToggleButtonGroupAction(
                        label: Text('Map'),
                        icon: FaIcon(FontAwesomeIcons.map, size: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
