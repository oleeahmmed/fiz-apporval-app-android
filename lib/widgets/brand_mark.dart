import 'package:material_ui/material_ui.dart';

import '../core/app_config.dart';
import '../core/app_theme.dart';

/// The FIZ emblem inside a white tile so the logo reads well on any colour.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.07),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandInk.withValues(alpha: 0.12),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      child: Image.asset(
        AppConfig.logoAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
