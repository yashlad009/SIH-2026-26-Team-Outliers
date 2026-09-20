import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

class CareLinkLogo extends StatelessWidget {
  final double width;
  final double height;
  final bool showText;
  final TextStyle? textStyle;

  const CareLinkLogo({
    super.key,
    this.width = 60,
    this.height = 60,
    this.showText = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(width * 0.1),
          child: SvgPicture.asset(
            'assets/images/carelink_logo.svg',
            fit: BoxFit.contain,
            placeholderBuilder: (context) => Icon(
              Icons.local_hospital_rounded,
              color: AppColors.primary,
              size: width * 0.5,
            ),
          ),
        ),
      ),
    );

    if (!showText) return logoWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        const SizedBox(width: 12),
        Text(
          'CareLink',
          style: textStyle ??
              const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}
