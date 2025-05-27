// lib/widgets/chart_wheel.dart
import 'package:flutter/material.dart';
import '../models/astro_models.dart';
import 'dart:math';

class ChartWheel extends StatelessWidget {
  final NatalChart natalChart;

  const ChartWheel({super.key, required this.natalChart});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _ChartPainter(natalChart),
        size: Size.infinite,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final NatalChart chart;

  // Краски для отрисовки
  final Paint _circlePaint = Paint()
    ..color = Colors.grey.shade600
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final Paint _houseLinePaint = Paint()
    ..color = Colors.blueGrey // Цвет для линий домов
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  final Paint _aspectLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final TextPainter _textPainter = TextPainter(textDirection: TextDirection.ltr);


  _ChartPainter(this.chart);

  // Helper function to convert astrological longitude (0-360) to canvas angle (radians)
  // Assumes 0 Aries is on the left (180 degrees math angle) and moves counter-clockwise
  double _getCanvasAngle(double longitude) {
    // 0 degrees Aries (astrological) is at 180 degrees (pi radians) on math circle
    // Angles increase counter-clockwise in math, just like astrological longitude
    return (longitude * pi / 180) + pi;
  }

  // Helper to get color for aspect type
  Color _getAspectColor(AspectType type) {
    switch (type) {
      case AspectType.conjunction:
        return Colors.purple;
      case AspectType.sextile:
        return Colors.blue;
      case AspectType.square:
        return Colors.red;
      case AspectType.trine:
        return Colors.green;
      case AspectType.opposition:
        return Colors.orange;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.width / 2.2; // Внешний радиус для символов знаков
    final innerRadius = outerRadius * 0.8; // Внутренний радиус для планет
    final houseRadius = innerRadius * 0.9; // Радиус для отображения куспидов домов

    final signSymbolStyle = TextStyle(color: Colors.black, fontSize: outerRadius * 0.07); // Размер шрифта для знаков
    final planetSymbolStyle = TextStyle(color: Colors.black, fontSize: innerRadius * 0.08); // Размер шрифта для планет
    final houseNumberStyle = TextStyle(color: Colors.black, fontSize: houseRadius * 0.05); // Размер шрифта для номеров домов


    // --- 1. Внешний круг (Зодиакальный круг) ---
    canvas.drawCircle(center, outerRadius, _circlePaint);


    // --- 2. Отрисовка знаков зодиака и делений градусов ---
    final double anglePerDegree = pi / 180; // 1 градус в радианах
    for (int i = 0; i < 360; i++) {
      final double currentAstrologicalLongitude = i.toDouble();
      final double angle = _getCanvasAngle(currentAstrologicalLongitude);

      // Отрисовка делений градусов
      double tickLength;
      if (i % 30 == 0) { // Каждые 30 градусов (начало знака)
        tickLength = outerRadius * 0.05;
        // Отрисовка символа знака Зодиака
        final sign = ZodiacSign.values[i ~/ 30]; // Знак зодиака по индексу
        final textOffset = Offset(
          center.dx + cos(angle + anglePerDegree * 15) * (outerRadius + tickLength + (outerRadius * 0.03)), // Смещение текста между делениями
          center.dy + sin(angle + anglePerDegree * 15) * (outerRadius + tickLength + (outerRadius * 0.03)),
        );
        _textPainter.text = TextSpan(text: sign.symbol, style: signSymbolStyle);
        _textPainter.layout();
        canvas.drawCircle(textOffset, _textPainter.width / 2 + 2, _circlePaint); // Кружок вокруг символа
        _textPainter.paint(canvas, textOffset - Offset(_textPainter.width / 2, _textPainter.height / 2));

      } else if (i % 5 == 0) { // Каждые 5 градусов
        tickLength = outerRadius * 0.02;
      } else { // Каждый градус
        tickLength = outerRadius * 0.01;
      }

      final p1 = Offset(center.dx + cos(angle) * outerRadius, center.dy + sin(angle) * outerRadius);
      final p2 = Offset(center.dx + cos(angle) * (outerRadius + tickLength), center.dy + sin(angle) * (outerRadius + tickLength));
      canvas.drawLine(p1, p2, _circlePaint);
    }

    // --- 3. Отрисовка куспидов домов ---
    // Внутренний круг для куспидов домов (или для размещения номеров домов)
    canvas.drawCircle(center, houseRadius, _circlePaint);

    for (final house in chart.houses) {
      final double houseAngle = _getCanvasAngle(house.cusp);

      // Линии куспидов домов от центра до внутреннего круга
      final p1 = center;
      final p2 = Offset(center.dx + cos(houseAngle) * houseRadius, center.dy + sin(houseAngle) * houseRadius);
      canvas.drawLine(p1, p2, _houseLinePaint);

      // Номера домов (размещаем ближе к центру или на середине сектора)
      final textOffset = Offset(
        center.dx + cos(houseAngle + (pi/12)) * (houseRadius * 0.7), // + pi/12 для размещения в середине дома
        center.dy + sin(houseAngle + (pi/12)) * (houseRadius * 0.7),
      );
      _textPainter.text = TextSpan(text: house.number.toString(), style: houseNumberStyle);
      _textPainter.layout();
      _textPainter.paint(canvas, textOffset - Offset(_textPainter.width / 2, _textPainter.height / 2));
    }


    // --- 4. Отрисовка планет ---
    // Отрисовка планет на innerRadius
    for (final position in chart.planetPositions) {
      final angle = _getCanvasAngle(position.longitude);
      final planetOffset = Offset(
        center.dx + cos(angle) * innerRadius,
        center.dy + sin(angle) * innerRadius,
      );
      _textPainter.text = TextSpan(text: position.planet.symbol, style: planetSymbolStyle);
      _textPainter.layout();
      canvas.drawCircle(planetOffset, _textPainter.width / 2 + 2, _circlePaint); // Кружок вокруг символа
      _textPainter.paint(canvas, planetOffset - Offset(_textPainter.width / 2, _textPainter.height / 2));
    }


    // --- 5. Отрисовка аспектов ---
    for (final aspect in chart.aspects) {
      final angle1 = _getCanvasAngle(chart.planetPositions
          .firstWhere((p) => p.planet == aspect.planet1)
          .longitude);
      final angle2 = _getCanvasAngle(chart.planetPositions
          .firstWhere((p) => p.planet == aspect.planet2)
          .longitude);

      final p1Offset = Offset(center.dx + cos(angle1) * innerRadius, center.dy + sin(angle1) * innerRadius);
      final p2Offset = Offset(center.dx + cos(angle2) * innerRadius, center.dy + sin(angle2) * innerRadius);

      _aspectLinePaint.color = _getAspectColor(aspect.type);
      canvas.drawLine(p1Offset, p2Offset, _aspectLinePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _ChartPainter && oldDelegate.chart != chart) {
      return true; // Перерисовать, если данные натальной карты изменились
    }
    return false; // Нет необходимости в перерисовке
  }
}