import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FullWidthButton extends StatelessWidget {
  const FullWidthButton({
    super.key,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    required this.buttonText,
  });

  final void Function()? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60.h,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: backgroundColor == null
              ? const LinearGradient(
                  colors: [Colors.tealAccent, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          buttonText,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: textColor ?? Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}
