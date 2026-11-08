import 'package:flutter/material.dart';

class DriveBrand extends StatelessWidget {
  const DriveBrand({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .25),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: _DriveCrest(Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APPISHOWDRIVE',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
              Text(
                'TWITCH + KICK · IN VIAGGIO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.local_shipping_outlined,
          color: Theme.of(context).colorScheme.secondary,
          size: 22,
        ),
      ],
    ),
  );
}

class _DriveCrest extends CustomPainter {
  final Color color;
  _DriveCrest(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 40);
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1, 1, 38, 38),
        const Radius.circular(12),
      ),
      paint,
    );
    final ears =
        Path()
          ..moveTo(11, 16)
          ..lineTo(8, 9)
          ..lineTo(17, 12)
          ..moveTo(24, 12)
          ..lineTo(32, 9)
          ..lineTo(30, 18);
    canvas.drawPath(ears, paint);
    canvas.drawOval(const Rect.fromLTWH(10, 12, 21, 21), paint);
    canvas.drawOval(const Rect.fromLTWH(15, 22, 12, 7), paint);
    paint.style = PaintingStyle.fill;
    for (final p in [
      const Offset(15, 19),
      const Offset(26, 19),
      const Offset(18, 25.5),
      const Offset(23, 25.5),
    ]) {
      canvas.drawCircle(p, 1.1, paint);
    }
  }

  @override
  bool shouldRepaint(_DriveCrest oldDelegate) => oldDelegate.color != color;
}
