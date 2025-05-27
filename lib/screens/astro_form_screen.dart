// lib/screens/astro_form_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/astro_models.dart';
import '../services/astro_service.dart';
import 'natal_chart_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Убедись, что этот импорт есть

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

  // ВНИМАНИЕ: API-ключ теперь загружается из .env файла
  // Убедитесь, что config.env существует в корне проекта и содержит OPENCAGEDATA_API_KEY
  final String _openCageDataApiKey = dotenv.env['OPENCAGEDATA_API_KEY'] ?? '';

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  /// Асинхронно получает географические координаты и смещение UTC
  /// для заданного места с помощью OpenCageData API.
  Future<Coordinates?> _fetchCoordinates(String place) async {
    if (_openCageDataApiKey.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API ключ OpenCageData не найден. Пожалуйста, проверьте config.env.')),
      );
      return null;
    }

    final encodedPlace = Uri.encodeComponent(place);
    final url = Uri.parse('https://api.opencagedata.com/geocode/v1/json?q=$encodedPlace&key=$_openCageDataApiKey&language=ru');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final lat = result['geometry']['lat'];
          final lng = result['geometry']['lng'];
          final timezoneOffsetString = result['annotations']['timezone']['offset_string'];
          return Coordinates(latitude: lat, longitude: lng, utcOffset: timezoneOffsetString);
        } else {
          if (!mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Место не найдено. Пожалуйста, проверьте написание.')),
          );
          return null;
        }
      } else {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка API геокодирования: ${response.statusCode}. Попробуйте позже.')),
        );
        print('OpenCageData API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
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

      // Комбинируем выбранные дату и время (это будет локальное время рождения)
      final birthDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final coords = await _fetchCoordinates(_placeController.text);

      if (!mounted) {
        setState(() { _isLoading = false; });
        return;
      }

      if (coords == null) {
        setState(() { _isLoading = false; });
        // Сообщение уже показано в _fetchCoordinates
        return;
      }

      // --- КОРРЕКТНОЕ ПРЕОБРАЗОВАНИЕ ВРЕМЕНИ В UTC ---
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

      // Преобразуем локальное время рождения в UTC
      // Важно: если birthDateTime уже содержит информацию о временной зоне,
      // то toUtc() учтет ее. Если нет (DateTime без временной зоны),
      // то subtract(timezoneOffset) является правильным подходом.
      // В Flutter, DateTime без временной зоны считается локальным.
      final birthDateTimeUtc = birthDateTime.subtract(timezoneOffset);

      // Используем AstroService.calculateNatalChart для получения полной карты
      final chart = AstroService.calculateNatalChart(
        name: _nameController.text,
        birthDateTime: birthDateTimeUtc, // ПЕРЕДАЕМ ВРЕМЯ В UTC!
        birthPlace: _placeController.text,
        latitude: coords.latitude,
        longitude: coords.longitude,
        utcOffset: coords.utcOffset, // Передаем смещение для информации, если нужно
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Введите данные рождения'),
        // Явно задаем цвета для AppBar, чтобы он был виден
        backgroundColor: Theme.of(context).colorScheme.primary, // Используем основной цвет из темы
        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Цвет текста на основном цвете
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Растягиваем элементы по ширине
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(), // Добавим рамку для лучшей видимости
                ),
                validator: (value) => value == null || value.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 16), // Увеличим отступ
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(
                  labelText: 'Место рождения',
                  border: OutlineInputBorder(), // Добавим рамку
                ),
                validator: (value) => value == null || value.isEmpty ? 'Введите место рождения' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Выберите дату рождения'
                      : 'Дата рождения: ${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                  style: Theme.of(context).textTheme.bodyLarge, // Чтобы текст был виден
                ),
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
              const SizedBox(height: 8), // Небольшой отступ между ListTile
              ListTile(
                title: Text(
                  _selectedTime == null
                      ? 'Выберите время рождения'
                      : 'Время рождения: ${_selectedTime!.format(context)}',
                  style: Theme.of(context).textTheme.bodyLarge, // Чтобы текст был виден
                ),
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
                  ? const Center(child: CircularProgressIndicator()) // Центрируем индикатор
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Рассчитать карту'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}