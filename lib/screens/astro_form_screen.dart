// lib/screens/astro_form_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/astro_models.dart';
import '../services/astro_service.dart';
import 'natal_chart_screen.dart';

class AstroFormScreen extends StatefulWidget {
  const AstroFormScreen({super.key});

  @override
  State<AstroFormScreen> createState() => _AstroFormScreenState();
}

class _AstroFormScreenState extends State<AstroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false; // Состояние загрузки

  // ВНИМАНИЕ: Ключ API для OpenCageData.
  // В реальном приложении этот ключ НЕ ДОЛЖЕН храниться так в открытом виде.
  // Рассмотрите использование переменных окружения, flutter_dotenv, или серверного прокси.
  static const String apiKey = '271307c7f21b4bd898e25b76561835aa';

  /// Асинхронно получает географические координаты и смещение UTC
  /// для заданного места с помощью OpenCageData API.
  Future<Coordinates?> _fetchCoordinates(String place) async {
    final url = Uri.parse('https://api.opencagedata.com/geocode/v1/json?q=$place&key=$apiKey&language=ru');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final lat = result['geometry']['lat'];
          final lng = result['geometry']['lng'];
          // OpenCageData предоставляет offset_string, например, "+03:00"
          final timezoneOffsetString = result['annotations']['timezone']['offset_string'];
          return Coordinates(latitude: lat, longitude: lng, utcOffset: timezoneOffsetString);
        } else {
          // Нет результатов для данного места
          if (!mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Место не найдено. Пожалуйста, проверьте написание.')),
          );
          return null;
        }
      } else {
        // Ошибка HTTP-статуса
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка API геокодирования: ${response.statusCode}')),
        );
        print('OpenCageData API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // Ошибка сети или парсинга
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети при получении координат. Проверьте подключение.')),
      );
      print('Ошибка при получении координат: $e');
      return null;
    }
  }

  /// Обрабатывает отправку формы: валидирует данные, получает координаты,
  /// рассчитывает натальную карту и переходит на экран результатов.
  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
      setState(() {
        _isLoading = true; // Начинаем загрузку
      });

      // Комбинируем выбранные дату и время
      final birthDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final coords = await _fetchCoordinates(_placeController.text);

      if (!mounted) {
        setState(() { _isLoading = false; }); // Завершаем загрузку, если виджет уже не смонтирован
        return;
      }

      if (coords == null) {
        setState(() { _isLoading = false; }); // Завершаем загрузку при ошибке координат
        // Сообщение уже показано в _fetchCoordinates
        return;
      }

      // --- КОРРЕКТНОЕ ПРЕОБРАЗОВАНИЕ ВРЕМЕНИ В UTC ---
      // Разбираем строку смещения UTC (например, "+03:00" или "-05:00")
      Duration timezoneOffset;
      try {
        final sign = coords.utcOffset.substring(0, 1);
        final parts = coords.utcOffset.substring(1).split(':');
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);

        if (sign == '+') {
          timezoneOffset = Duration(hours: hours, minutes: minutes);
        } else if (sign == '-') {
          timezoneOffset = Duration(hours: -hours, minutes: -minutes);
        } else {
          throw FormatException('Неверный формат UTC смещения: ${coords.utcOffset}');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка разбора часового пояса: ${coords.utcOffset}')),
        );
        setState(() { _isLoading = false; });
        return;
      }

      // Если birthDateTime - это локальное время, переводим его в UTC для астрологических расчетов.
      final birthDateTimeUtc = birthDateTime.subtract(timezoneOffset);

      // Используем AstroService.calculateNatalChart для получения полной карты
      final chart = AstroService.calculateNatalChart(
        name: _nameController.text,
        birthDateTime: birthDateTimeUtc, // ПЕРЕДАЕМ ВРЕМЯ В UTC!
        birthPlace: _placeController.text,
        latitude: coords.latitude,
        longitude: coords.longitude,
        utcOffset: coords.utcOffset, // Передаем смещение, если оно нужно для отображения
        aspectsOrb: 8.0, // Пример орбиса для аспектов
      );

      if (!mounted) {
        setState(() { _isLoading = false; });
        return;
      }

      setState(() {
        _isLoading = false; // Завершаем загрузку
      });

      // Переходим на экран натальной карты
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NatalChartScreen(natalChart: chart),
        ),
      );
    } else {
      // Сообщение, если не все поля заполнены
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля (включая дату и время).')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Введите данные рождения')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Имя'),
                validator: (value) => value == null || value.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: 'Место рождения'),
                validator: (value) => value == null || value.isEmpty ? 'Введите место рождения' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Выберите дату рождения'
                    : 'Дата рождения: ${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              ListTile(
                title: Text(_selectedTime == null
                    ? 'Выберите время рождения'
                    : 'Время рождения: ${_selectedTime!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _selectedTime = time);
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator() // Показываем индикатор загрузки
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Рассчитать карту'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}