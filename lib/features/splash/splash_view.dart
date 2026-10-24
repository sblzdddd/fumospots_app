import 'dart:async';

import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/i18n/i18n.dart';
import '../home/brand_logo.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  /// Halfway through the splash's minimum time on screen (700ms).
  static const _peekDelay = Duration(milliseconds: 350);
  static const _chenAsset = 'assets/Chen_W.png';

  Timer? _peekTimer;
  var _peeking = false;
  var _precached = false;
  String? _version;

  @override
  void initState() {
    super.initState();
    _peekTimer = Timer(_peekDelay, () {
      if (mounted) setState(() => _peeking = true);
    });
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = info.version);
    } catch (_) {
      return;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    precacheImage(const AssetImage(_chenAsset), context);
  }

  @override
  void dispose() {
    _peekTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    var chenSize = size.width * 0.76;
    final heightCap = size.height * 0.46;
    if (heightCap < chenSize) chenSize = heightCap;
    if (chenSize > 380) chenSize = 380;
    final headReveal = chenSize * _ChenPeek.headFraction;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FumospotsBrandLogo(height: 72),
                const SizedBox(height: 32),
                M3ELoadingIndicator(
                  color: colors.primary,
                  semanticsLabel: context.t(S.loadingApp),
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: headReveal + 20,
            child: Text(
              _version ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _ChenPeek(
              shown: _peeking,
              size: chenSize,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChenPeek extends StatelessWidget {
  const _ChenPeek({
    required this.shown,
    required this.size,
    required this.color,
  });

  final bool shown;
  final double size;
  final Color color;

  /// Top of the artwork through the chin. The neck gap sits just past this.
  static const headFraction = 532 / 1024;

  static const _motion = CupertinoMotion.snappy(
    duration: Duration(milliseconds: 620),
    extraBounce: 0.04,
  );

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      value: shown ? 1.0 : 0.0,
      motion: _motion,
      builder: (context, t, child) {
        // Clamp overshoot so the spring pop never uncovers the body.
        final travel = t.clamp(0.0, 1.0);
        final dy = size * (1 - headFraction * travel);
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: IgnorePointer(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: Image.asset(
            _SplashViewState._chenAsset,
            width: size,
            height: size,
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
