// lib/screens/natal_chart_screen.dart
import 'package:flutter/material.dart';
import '../models/astro_models.dart';
import '../widgets/chart_wheel.dart';

class NatalChartScreen extends StatelessWidget {
  final NatalChart natalChart;

  const NatalChartScreen({super.key, required this.natalChart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Натальная карта: ${natalChart.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Можно добавить небольшой блок с общей информацией о рождении здесь
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'Дата: ${natalChart.birthDateTime.day}.${natalChart.birthDateTime.month}.${natalChart.birthDateTime.year} '
                    'Время: ${natalChart.birthDateTime.hour.toString().padLeft(2, '0')}:${natalChart.birthDateTime.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Место: ${natalChart.birthPlace} (${natalChart.latitude.toStringAsFixed(2)}, ${natalChart.longitude.toStringAsFixed(2)})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Карта'),
                Tab(text: 'Планеты'),
                Tab(text: 'Аспекты'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildChartTab(),
                  _buildPlanetsTab(),
                  _buildAspectsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ChartWheel(natalChart: natalChart),
      ),
    );
  }

  Widget _buildPlanetsTab() {
    if (natalChart.planetPositions.isEmpty) {
      return const Center(child: Text('Нет данных о планетах'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: natalChart.planetPositions.length,
      itemBuilder: (context, index) {
        final position = natalChart.planetPositions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                position.planet.symbol,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(position.planet.label), // ИСПОЛЬЗУЕМ LABEL
            subtitle: Text(
              '${position.sign.symbol} ${position.sign.label} ${position.degree}°${position.minute}′', // ИСПОЛЬЗУЕМ LABEL
            ),
            trailing: Text(
              'Дом ${position.house}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAspectsTab() {
    if (natalChart.aspects.isEmpty) {
      return const Center(child: Text('Аспекты не найдены'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: natalChart.aspects.length,
      itemBuilder: (context, index) {
        final aspect = natalChart.aspects[index];
        final aspectColor = _getAspectColor(aspect.type);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: aspectColor.withAlpha((0.2 * 255).round()),
              child: Text(
                aspect.type.symbol,
                style: TextStyle(color: aspectColor, fontSize: 20),
              ),
            ),
            title: Text(
              // ИСПОЛЬЗУЕМ LABEL для планет и типа аспекта
              '${aspect.planet1.symbol} ${aspect.planet1.label} ${aspect.type.symbol} ${aspect.planet2.symbol} ${aspect.planet2.label}',
            ),
            subtitle: Text(aspect.type.label), // ИСПОЛЬЗУЕМ LABEL
            trailing: Text(
              '${aspect.orb.toStringAsFixed(2)}°',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }

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
}