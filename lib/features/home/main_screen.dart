import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n/i18n.dart';
import '../auth/auth_controller.dart';
import '../auth/login/auth_login_view.dart';
import '../map/map_model.dart';
import '../map/spot_map_view.dart';
import '../post/detail/post_detail_sheet.dart';
import '../post/feed/post_feed_view.dart';
import '../post/post_model.dart';
import '../settings/visual_settings_controller.dart';
import '../upload/upload_view.dart';
import '../user/user_view.dart';
import 'bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final VisualSettingsController _visual =
      GetIt.instance<VisualSettingsController>();
  int _selectedIndex = 0;
  int? _selectedPostId;
  bool _mapVisited = false;
  MapFocusTarget? _mapFocus;
  final GlobalKey _feedKey = GlobalKey();

  bool get _onPostsPage => _selectedIndex == 0;

  @override
  void initState() {
    super.initState();
    if (mapPageEnabled && _visual.startPage == HomeStartPage.map) {
      _selectedIndex = 1;
      _mapVisited = true;
    }
    _visual.addListener(_onChanged);
  }

  @override
  void dispose() {
    _visual.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openPost(int id) async {
    setState(() => _selectedPostId = id);
    PostLatLng? showInMapAt;
    await showPostDetailSheet(
      context,
      id,
      onShowInMap: _onPostsPage && mapPageEnabled
          ? (location) => showInMapAt = location
          : null,
    );
    if (!mounted) {
      return;
    }
    final focus = showInMapAt;
    if (focus != null) {
      setState(() {
        _selectedIndex = 1;
        _mapVisited = true;
        _selectedPostId = id;
        _mapFocus = MapFocusTarget(
          lat: focus.lat,
          lng: focus.lng,
          generation: (_mapFocus?.generation ?? 0) + 1,
        );
      });
      return;
    }
    setState(() => _selectedPostId = null);
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (mapPageEnabled && index == 1) {
        _mapVisited = true;
      }
    });
  }

  void _onAddPressed() {
    unawaited(_openComposer());
  }

  Future<void> _openComposer() async {
    final auth = GetIt.instance<AuthController>();
    await auth.init();
    if (!mounted) return;
    if (!auth.isSignedIn || !auth.hasUsername) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const AuthLoginView()),
      );
      if (!mounted || !auth.isSignedIn || !auth.hasUsername) return;
    }
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const UploadView()),
    );
    if (!mounted || message == null || message.isEmpty) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t(message))));
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final cs = Theme.of(context).colorScheme;
    const maxBarWidth = 400.0;
    const sideInset = 24.0;
    const bottomOffset = 8.0;
    final media = MediaQuery.of(context);
    final availableWidth =
        media.size.width - media.padding.horizontal - sideInset * 2;
    final barWidth =
        availableWidth < maxBarWidth ? availableWidth : maxBarWidth;

    final isLight = Theme.of(context).brightness == Brightness.light;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: cs.surface,
      systemNavigationBarDividerColor: cs.surface,
      systemNavigationBarIconBrightness:
          isLight ? Brightness.dark : Brightness.light,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: BottomBar(
          layout: BottomBarLayout(
            width: barWidth,
            maxWidth: maxBarWidth,
            offset: bottomOffset,
            borderRadius: const BorderRadius.all(Radius.circular(32)),
            clip: Clip.none,
          ),
          motion: const BottomBarMotion.cupertino(
            preset: BottomBarCupertinoMotion.snappy,
            duration: Duration(milliseconds: 460),
            extraBounce: 0.03,
          ),
          scrollBehavior: const BottomBarScrollBehavior(
            hideOnScroll: true,
            showAtStart: true,
          ),
          theme: BottomBarThemeData(
            barDecoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            iconDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            iconWidth: 40,
            iconHeight: 40,
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              PostFeedView(
                key: _feedKey,
                contentInsetTop: topInset,
                onOpenPost: _openPost,
              ),
              if (mapPageEnabled)
                if (_mapVisited)
                  SpotMapView(
                    contentInsetTop: topInset,
                    selectedPostId: _selectedPostId,
                    focusTarget: _mapFocus,
                    onOpenPost: _openPost,
                  )
                else
                  const SizedBox.expand(),
              const UserView(),
            ],
          ),
          child: FloatingBottomDock(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            onAddPressed: _onAddPressed,
            blurEnabled: _visual.blurEnabled,
            showMap: mapPageEnabled,
          ),
        ),
      ),
    );
  }
}
