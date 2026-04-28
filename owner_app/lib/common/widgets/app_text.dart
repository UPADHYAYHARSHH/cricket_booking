import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;
  final TextAlign align;
  final TextStyle? textStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText({
    super.key,
    required this.text,
    this.size = 14,
    this.weight = FontWeight.w400,
    this.color,
    this.align = TextAlign.start,
    this.textStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: (textStyle ??
              TextStyle(
                fontSize: size,
                fontWeight: weight,
                color: color,
              ))
          .copyWith(
        color: color ?? textStyle?.color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
