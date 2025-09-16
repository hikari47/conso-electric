import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SimpleLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final String title;

  const SimpleLineChart({
    Key? key,
    required this.data,
    required this.labels,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Aucune donnée disponible')),
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: CustomPaint(
                painter: LineChartPainter(
                  data: data,
                  labels: labels,
                  maxValue: maxValue,
                  minValue: minValue,
                  color: AppTheme.primaryColor,
                ),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double maxValue;
  final double minValue;
  final Color color;

  LineChartPainter({
    required this.data,
    required this.labels,
    required this.maxValue,
    required this.minValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final fillPaint =
        Paint()
          ..color = color.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final range = maxValue - minValue;
    final stepY = range > 0 ? size.height / range : 0;

    // Dessiner la ligne
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minValue) * stepY);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fermer le path pour le remplissage
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Dessiner le remplissage puis la ligne
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Dessiner les points
    final pointPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minValue) * stepY);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
