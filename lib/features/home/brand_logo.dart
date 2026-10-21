import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FumospotsBrandLogo extends StatelessWidget {
  const FumospotsBrandLogo({super.key, this.height = 28});

  final double height;

  static const _viewBoxWidth = 208.9;
  static const _viewBoxHeight = 90.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = height * _viewBoxWidth / _viewBoxHeight;

    return SvgPicture.asset(
      dark ? 'assets/brand/logo-dark.svg' : 'assets/brand/logo.svg',
      width: width,
      height: height,
      semanticsLabel: 'Fumospots',
    );
  }
}
