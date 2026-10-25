import 'dart:async';

import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/i18n/i18n.dart';
import '../home/brand_logo.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key, this.exiting = false, this.onExitEnd});

  final bool exiting;

  final VoidCallback? onExitEnd;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const _peekDelay = Duration(milliseconds: 350);
  static const _chenAsset = 'assets/Chen_W.png';
  static const _exitMotion = CupertinoMotion.smooth(
    duration: Duration(milliseconds: 500),
  );
  static const _logoHeight = 72.0;
  static const _logoGap = 32.0;
  static const _indicatorSize = 38.0;

  final _titleKey = GlobalKey();
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

  void _onExitStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !widget.exiting) return;
    widget.onExitEnd?.call();
  }

  Offset _titleOrigin(BuildContext context) {
    final measured = _measuredTitleCenter(context);
    if (measured != null) return measured;
    final size = MediaQuery.sizeOf(context);
    const columnHeight = _logoHeight + _logoGap + _indicatorSize;
    return Offset(
      size.width / 2,
      (size.height - columnHeight) / 2 + _logoHeight / 2,
    );
  }

  Offset? _measuredTitleCenter(BuildContext ancestorContext) {
    final titleBox = _titleKey.currentContext?.findRenderObject() as RenderBox?;
    final ancestor = ancestorContext.findRenderObject() as RenderBox?;
    if (titleBox == null ||
        ancestor == null ||
        !titleBox.attached ||
        !ancestor.attached ||
        !titleBox.hasSize ||
        !ancestor.hasSize) {
      return null;
    }
    try {
      return titleBox.localToGlobal(
        titleBox.size.center(Offset.zero),
        ancestor: ancestor,
      );
    } on FlutterError {
      return null;
    }
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

    return SingleMotionBuilder(
      value: widget.exiting ? 0 : 1,
      motion: _exitMotion,
      onAnimationStatusChanged: _onExitStatus,
      builder: (context, scale, child) {
        return _SplashCircleMask(
          scale: scale,
          origin: _titleOrigin(context),
          child: child!,
        );
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FumospotsBrandLogo(key: _titleKey, height: _logoHeight),
                  const SizedBox(height: _logoGap),
                  M3ELoadingIndicator(
                    color: colors.primary,
                    semanticsLabel: context.t(S.loadingApp),
                    constraints: const BoxConstraints.tightFor(
                      width: _indicatorSize,
                      height: _indicatorSize,
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
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
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
      ),
    );
  }
}

class _SplashCircleMask extends StatelessWidget {
  const _SplashCircleMask({
    required this.scale,
    required this.origin,
    required this.child,
  });

  final double scale;
  final Offset origin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = scale.clamp(0.0, 1.0);
    if (t >= 1) return child;
    return ClipPath(
      clipBehavior: Clip.antiAlias,
      clipper: _SplashCircleClipper(scale: t, origin: origin),
      child: child,
    );
  }
}

class _SplashCircleClipper extends CustomClipper<Path> {
  const _SplashCircleClipper({required this.scale, required this.origin});

  final double scale;
  final Offset origin;

  @override
  Path getClip(Size size) {
    if (scale <= 0 || size.isEmpty) return Path();
    final dx = origin.dx > size.width - origin.dx
        ? origin.dx
        : size.width - origin.dx;
    final dy = origin.dy > size.height - origin.dy
        ? origin.dy
        : size.height - origin.dy;
    final radius = Offset(dx, dy).distance * scale;
    return Path()..addOval(Rect.fromCircle(center: origin, radius: radius));
  }

  @override
  bool shouldReclip(covariant _SplashCircleClipper oldClipper) {
    return oldClipper.scale != scale || oldClipper.origin != origin;
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

  static const headFraction = 725 / 1024;

  static const _motion = CupertinoMotion.snappy(
    duration: Duration(milliseconds: 300),
    extraBounce: 0.3,
  );

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      value: shown ? 1.0 : 0.0,
      motion: _motion,
      builder: (context, t, child) {
        final travel = t;
        final dy = size * (1 - headFraction * travel);
        return Transform.translate(offset: Offset(0, dy), child: child);
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
