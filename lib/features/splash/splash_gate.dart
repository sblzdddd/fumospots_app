import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import '../post/feed/post_feed_controller.dart';
import 'splash_view.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const _minVisible = Duration(milliseconds: 1000);
  static const _maxVisible = Duration(seconds: 8);

  final PostFeedController _feed = GetIt.instance<PostFeedController>();
  Timer? _minTimer;
  Timer? _maxTimer;
  var _minElapsed = false;
  var _timedOut = false;
  var _hiding = false;
  var _gone = false;

  @override
  void initState() {
    super.initState();
    _feed.addListener(_onFeed);
    _minTimer = Timer(_minVisible, () {
      _minElapsed = true;
      _tryHide();
    });
    _maxTimer = Timer(_maxVisible, () {
      _minElapsed = true;
      _timedOut = true;
      _tryHide();
    });
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _feed.removeListener(_onFeed);
    super.dispose();
  }

  void _onFeed() => _tryHide();

  void _finishExit() {
    if (_hiding && mounted && !_gone) {
      setState(() => _gone = true);
    }
  }

  bool get _homeReady => !_feed.showingSkeletons;

  void _tryHide() {
    if (!mounted || _hiding || !_minElapsed) {
      return;
    }
    if (!_homeReady && !_timedOut) {
      return;
    }
    _minTimer?.cancel();
    _maxTimer?.cancel();
    setState(() => _hiding = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(excluding: !_gone && !_hiding, child: widget.child),
        if (!_gone)
          IgnorePointer(
            ignoring: _hiding,
            child: SplashView(exiting: _hiding, onExitEnd: _finishExit),
          ),
      ],
    );
  }
}
