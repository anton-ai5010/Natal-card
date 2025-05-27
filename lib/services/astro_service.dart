// lib/services/astro_service.dart
import 'dart:math' as math;
import '../models/astro_models.dart';

class AstroService {
  static const double degreesToRadians = math.pi / 180;
  static const double radiansToDegrees = 180 / math.pi;
  static const double eclipticObliquity = 23.4397; // Наклон эклиптики

  /// Вычисляет Юлианскую дату (Julian Date - JD) для заданной даты и времени.
  /// JD - это непрерывное число дней с определенной начальной точки.
  static double getJulianDate(DateTime dateTime) {
    int year = dateTime.year;
    int month = dateTime.month;
    int day = dateTime.day;
    // Время в долях дня
    double hour = dateTime.hour + dateTime.minute / 60.0 + dateTime.second / 3600.0;

    // Коррекция для месяцев январь и февраль в расчетах JD
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    // Алгоритм для расчета JD (формула Дж. Мии)
    int A = year ~/ 100;
    int B = 2 - A + (A ~/ 4);

    double jd = (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day + (hour / 24.0) + B - 1524.5;

    return jd;
  }

  /// Нормализует угол, чтобы он находился в диапазоне [0, 360) градусов.
  static double normalizeAngle(double angle) {
    double result = angle % 360;
    if (result < 0) {
      result += 360;
    }
    return result;
  }

  /// Определяет знак Зодиака по заданной эклиптической долготе.
  static ZodiacSign getZodiacSign(double longitude) {
    // Делим долготу на 30 градусов (размер знака) и берем целую часть как индекс.
    // Используем % 12, чтобы убедиться, что индекс находится в пределах 0-11.
    final index = (longitude ~/ 30) % 12;
    return ZodiacSign.values[index];
  }

  /// Создает объект PlanetPosition на основе планеты и ее долготы.
  /// Дом планеты пока устанавливается в 1, будет рассчитан позже.
  static PlanetPosition createPlanetPosition(Planet planet, double longitude, {int house = 1}) {
    final sign = getZodiacSign(longitude);
    final degree = longitude.floor() % 30; // Градус внутри знака
    final minute = (((longitude - longitude.floor()) * 60)).round(); // Минуты градуса
    return PlanetPosition(
      planet: planet,
      longitude: longitude,
      sign: sign,
      degree: degree,
      minute: minute,
      house: house, // Дом будет обновлен после расчета всех домов
    );
  }

  /// Рассчитывает куспиды домов по системе Равных Домов (Equal Houses).
  /// Требуется точная долгота Асцендента.
  static List<House> calculateHousesEqual(double ascendantLongitude) {
    List<House> houses = [];
    for (int i = 0; i < 12; i++) {
      // Каждый следующий куспид дома на 30 градусов дальше предыдущего
      double cuspLongitude = normalizeAngle(ascendantLongitude + i * 30);
      ZodiacSign sign = getZodiacSign(cuspLongitude);
      houses.add(House(number: i + 1, cusp: cuspLongitude, sign: sign));
    }
    return houses;
  }

  /// Определяет дом, в котором находится планета, на основе ее долготы и списка домов.
  static int getHouseOfPlanet(double planetLongitude, List<House> houses) {
    // Сортируем дома по куспидам на всякий случай, хотя для Equal Houses это не так критично
    houses.sort((a, b) => a.cusp.compareTo(b.cusp));

    for (int i = 0; i < houses.length; i++) {
      final currentHouseCusp = houses[i].cusp;
      final nextHouseCusp = houses[(i + 1) % houses.length].cusp; // Кольцевой переход

      if (currentHouseCusp <= nextHouseCusp) {
        // Обычный случай: куспиды идут по возрастанию
        if (planetLongitude >= currentHouseCusp && planetLongitude < nextHouseCusp) {
          return houses[i].number;
        }
      } else {
        // Случай перехода через 0/360 градусов (например, 12-й дом до 1-го)
        if (planetLongitude >= currentHouseCusp || planetLongitude < nextHouseCusp) {
          return houses[i].number;
        }
      }
    }
    // Если по какой-то причине дом не найден (маловероятно при корректных данных)
    return 0; // Или можно выбросить исключение
  }


  /// --- Методы для расчета позиций планет (упрощенные формулы) ---

  static PlanetPosition calculateSunPosition(DateTime dateTime) {
    double jd = getJulianDate(dateTime);
    double d = jd - 2451545.0; // Количество дней с 1 января 2000 года, 12:00 UT
    double L = (280.460 + 0.9856474 * d); // Средняя долгота Солнца
    double g = (357.528 + 0.9856003 * d); // Средняя аномалия Солнца

    g = normalizeAngle(g);
    double gRad = g * degreesToRadians;

    double longitude = L + 1.915 * math.sin(gRad) + 0.020 * math.sin(2 * gRad);
    longitude = normalizeAngle(longitude);
    return createPlanetPosition(Planet.sun, longitude);
  }

  static PlanetPosition calculateMoonPosition(DateTime dateTime) {
    double jd = getJulianDate(dateTime);
    double d = jd - 2451545.0;
    double L = (218.316 + 13.176396 * d); // Средняя долгота Луны
    double M = (134.963 + 13.064993 * d); // Средняя аномалия Луны
    double F = (93.272 + 13.229350 * d); // Аргумент широты Луны

    M = normalizeAngle(M);
    F = normalizeAngle(F);
    double mRad = M * degreesToRadians;
    double fRad = F * degreesToRadians;

    double longitude = L + 6.289 * math.sin(mRad)
        + 1.274 * math.sin(2 * fRad - mRad)
        + 0.658 * math.sin(2 * fRad)
        + 0.214 * math.sin(2 * mRad)
        - 0.186 * math.sin(mRad - 2 * fRad)
        - 0.114 * math.sin(2 * fRad - 2 * mRad);
    longitude = normalizeAngle(longitude);
    return createPlanetPosition(Planet.moon, longitude);
  }

  static PlanetPosition calculateMercuryPosition(DateTime dateTime) {
    double jd = getJulianDate(dateTime);
    double d = jd - 2451545.0;
    double t = d / 36525.0; // Юлианские столетия с J2000.0
    double L = normalizeAngle(252.2509 + 149472.6747 * t); // Средняя долгота
    double M = normalizeAngle(357.5291 + 35999.0503 * t); // Средняя аномалия Земли
    double mRad = M * degreesToRadians;
    double C = 23.4400 * math.sin(mRad) // Центр
        + 2.9818 * math.sin(2 * mRad)
        + 0.5255 * math.sin(3 * mRad)
        + 0.1058 * math.sin(4 * mRad)
        + 0.0241 * math.sin(5 * mRad);
    double longitude = normalizeAngle(L + C);
    return createPlanetPosition(Planet.mercury, longitude);
  }

  static PlanetPosition calculateVenusPosition(DateTime dateTime) {
    double jd = getJulianDate(dateTime);
    double d = jd - 2451545.0;
    double t = d / 36525.0;
    double L = normalizeAngle(181.9798 + 58517.8156 * t);
    double M = normalizeAngle(357.5291 + 35999.0503 * t);
    double mRad = M * degreesToRadians;
    double C = 12.0507 * math.sin(mRad)
        + 0.4919 * math.sin(2 * mRad)
        + 0.1378 * math.sin(3 * mRad)
        + 0.0324 * math.sin(4 * mRad);
    double longitude = normalizeAngle(L + C);
    return createPlanetPosition(Planet.venus, longitude);
  }

  static PlanetPosition calculateMarsPosition(DateTime dateTime) {
    double jd = getJulianDate(dateTime);
    double d = jd - 2451545.0;
    double t = d / 36525.0;
    double L = normalizeAngle(355.4330 + 19140.2993 * t);
    double M = normalizeAngle(357.5291 + 35999.0503 * t);
    double mRad = M * degreesToRadians;
    double C = 10.6912 * math.sin(mRad)
        + 0.6228 * math.sin(2 * mRad)
        + 0.0503 * math.sin(3 * mRad)
        + 0.0046 * math.sin(4 * mRad);
    double longitude = normalizeAngle(L + C);
    return createPlanetPosition(Planet.mars, longitude);
  }

  static PlanetPosition calculateJupiterPosition(DateTime dateTime) {
    double jd = getJulianDate(dateTime);
    double d = jd - 2451545.0;
    double t = d / 36525.0;
    double L = normalizeAngle(34.3515 + 3034.9057 * t);
    double M = normalizeAngle(357.5291 + 35999.0503 * t);
    double mRad = M * degreesToRadians;
    double C = 5.5549 * math.sin(mRad)
        + 0.1683 * math.sin(2 * mRad)
        + 0.0071 * math.sin(3 * mRad);
    double longitude = normalizeAngle(L + C);
    return createPlanetPosition(Planet.jupiter, longitude);
  }

  // --- Заглушки для оставшихся планет (требуют реализации формул) ---
  static PlanetPosition calculateSaturnPosition(DateTime dateTime) {
    // TODO: Добавить формулы для Сатурна
    return createPlanetPosition(Planet.saturn, 0.0); // Временная заглушка
  }

  static PlanetPosition calculateUranusPosition(DateTime dateTime) {
    // TODO: Добавить формулы для Урана
    return createPlanetPosition(Planet.uranus, 0.0); // Временная заглушка
  }

  static PlanetPosition calculateNeptunePosition(DateTime dateTime) {
    // TODO: Добавить формулы для Нептуна
    return createPlanetPosition(Planet.neptune, 0.0); // Временная заглушка
  }

  static PlanetPosition calculatePlutoPosition(DateTime dateTime) {
    // TODO: Добавить формулы для Плутона
    return createPlanetPosition(Planet.pluto, 0.0); // Временная заглушка
  }

  /// --- Общий метод для расчета всех положений планет ---
  static List<PlanetPosition> calculateAllPlanetPositions(DateTime dateTime) {
    List<PlanetPosition> positions = [];
    positions.add(calculateSunPosition(dateTime));
    positions.add(calculateMoonPosition(dateTime));
    positions.add(calculateMercuryPosition(dateTime));
    positions.add(calculateVenusPosition(dateTime));
    positions.add(calculateMarsPosition(dateTime));
    positions.add(calculateJupiterPosition(dateTime));
    positions.add(calculateSaturnPosition(dateTime));
    positions.add(calculateUranusPosition(dateTime));
    positions.add(calculateNeptunePosition(dateTime));
    positions.add(calculatePlutoPosition(dateTime));
    return positions;
  }

  /// --- Расчет Local Sidereal Time (Местное Звездное Время) ---
  /// LST критически важно для расчета Асцендента и куспидов домов.
  /// [dateTime] - дата и время рождения.
  /// [longitude] - географическая долгота места рождения в градусах.
  static double calculateLocalSiderealTime(DateTime dateTime, double longitude) {
    double jd = getJulianDate(dateTime);
    // Часть суток в универсальном времени (UT)
    double ut = dateTime.hour + dateTime.minute / 60.0 + dateTime.second / 3600.0;

    // Расчет юлианских столетий с J2000.0 (JD 2451545.0)
    double T = (jd - 2451545.0) / 36525.0;

    // Среднее звездное время в Гринвиче (Greenwich Mean Sidereal Time - GMST) в 0h UT
    double GMST0 = 280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * T * T - T * T * T / 38710000;
    GMST0 = normalizeAngle(GMST0);

    // Добавляем поправку за время UT
    double GMST = GMST0 + 360.98564736629 * ut / 24.0;
    GMST = normalizeAngle(GMST);

    // Местное звездное время (Local Sidereal Time - LST)
    double LST = GMST + longitude;
    LST = normalizeAngle(LST);

    return LST;
  }

  /// --- Расчет Асцендента ---
  /// Этот метод является заглушкой и требует более сложной реализации
  /// с использованием LST, широты и наклона эклиптики.
  /// Формула для Асцендента сложна из-за работы с квадрантами функции atan.
  ///
  /// [lst] - местное звездное время в градусах.
  /// [latitude] - географическая широта места рождения в градусах.
  static double calculateAscendant(double lst, double latitude) {
    // ВНИМАНИЕ: Это упрощенная заглушка. Для точного расчета Асцендента
    // требуется более сложная формула, учитывающая квадранты.
    // Пример начальной формулы (неполной):
    // double sinAsc = -math.cos(lst * degreesToRadians) /
    //     (math.cos(latitude * degreesToRadians) * math.sin(eclipticObliquity * degreesToRadians) +
    //         math.sin(latitude * degreesToRadians) * math.cos(eclipticObliquity * degreesToRadians) * math.tan(lst * degreesToRadians));
    // double ascendant = math.asin(sinAsc) * radiansToDegrees;

    return 0.0; // Временная заглушка.
  }

  /// --- Расчет Медиум Цели (MC) ---
  /// Этот метод является заглушкой и требует более сложной реализации.
  /// [lst] - местное звездное время в градусах.
  static double calculateMC(double lst) {
    // ВНИМАНИЕ: Это упрощенная заглушка. Точный MC = LST - 90,
    // но с учетом квадрантов.
    return normalizeAngle(lst + 90); // Временная заглушка, MC = LST + 90 (для северного полушария)
  }

  /// --- Расчет аспектов между планетами ---
  /// [planetPositions] - список положений всех планет.
  /// [orb] - допустимый орбис (отклонение) для аспекта в градусах.
  static List<Aspect> calculateAspects(List<PlanetPosition> planetPositions, double orb) {
    List<Aspect> aspects = [];

    // Перебираем все уникальные пары планет
    for (int i = 0; i < planetPositions.length; i++) {
      for (int j = i + 1; j < planetPositions.length; j++) {
        final p1 = planetPositions[i];
        final p2 = planetPositions[j];

        // Вычисляем угловое расстояние между планетами
        double angleDiff = (p1.longitude - p2.longitude).abs();
        angleDiff = normalizeAngle(angleDiff);

        // Если разница больше 180 градусов, берем меньший угол (например, 270 градусов это то же что 90)
        if (angleDiff > 180) {
          angleDiff = 360 - angleDiff;
        }

        // Проверяем все возможные типы аспектов
        for (var aspectType in AspectType.values) {
          // Если разница в угле находится в пределах орбиса от идеального угла аспекта
          if ((angleDiff - aspectType.angle).abs() <= orb) {
            aspects.add(Aspect(
              planet1: p1.planet,
              planet2: p2.planet,
              type: aspectType,
              orb: (angleDiff - aspectType.angle).abs(), // Точный орбис аспекта
            ));
          }
        }
      }
    }
    return aspects;
  }

  /// --- Основной метод для расчета всей натальной карты ---
  /// Этот метод будет агрегировать все расчеты.
  /// [name] - имя пользователя.
  /// [birthDateTime] - дата и время рождения.
  /// [birthPlace] - место рождения.
  /// [latitude] - широта места рождения.
  /// [longitude] - долгота места рождения.
  /// [utcOffset] - смещение часового пояса от UTC (строка, например, "+03:00").
  /// [aspectsOrb] - орбис для расчета аспектов.
  static NatalChart calculateNatalChart({
    required String name,
    required DateTime birthDateTime,
    required String birthPlace,
    required double latitude,
    required double longitude,
    required String utcOffset, // Строка UTC смещения (например, "+03:00")
    double aspectsOrb = 8.0, // Орбис по умолчанию
  }) {
    // 1. Рассчитываем местное звездное время
    // TODO: Здесь нужно будет привести utcOffset к числу для DateTime с учетом часового пояса
    // Для начала, можно использовать birthDateTime как оно есть, если оно уже в локальном времени
    // или перевести его в UT.
    // Пока что будем использовать birthDateTime напрямую, предполагая, что оно в "местном" времени для расчетов LST.
    // В реальном приложении нужно будет корректно учесть часовой пояс и UTC.
    // Например, если birthDateTime это локальное время, нужно его перевести в UTC,
    // а затем использовать это UTC время для getJulianDate и LST.

    // Пример как перевести локальное время в UTC, если birthDateTime - это локальное время
    // DateTime birthDateTimeUtc = birthDateTime.toUtc();
    // double lst = calculateLocalSiderealTime(birthDateTimeUtc, longitude);

    // Для текущего упрощенного примера будем использовать birthDateTime как есть
    double lst = calculateLocalSiderealTime(birthDateTime, longitude);


    // 2. Рассчитываем Асцендент (пока заглушка)
    double ascendantLongitude = calculateAscendant(lst, latitude);
    if (ascendantLongitude == 0.0) {
      // Если Асцендент еще не реализован, можно использовать фиктивное значение,
      // или выбросить ошибку, или сделать его 0 (Овен 0 градусов)
      // В равных домах Асцендент - это куспид 1-го дома
      // Пока что для Equal Houses без точного Асцендента, можно просто взять 0 градусов Овна для 1 дома.
      // Но для реальной астрологии, Асцендент ОЧЕНЬ важен.
      ascendantLongitude = 0.0; // Временное решение для продолжения
    }


    // 3. Рассчитываем куспиды домов
    List<House> houses = calculateHousesEqual(ascendantLongitude);

    // 4. Рассчитываем позиции всех планет
    List<PlanetPosition> planetPositions = calculateAllPlanetPositions(birthDateTime);

    // 5. Обновляем дом для каждой планеты
    List<PlanetPosition> updatedPlanetPositions = planetPositions.map((p) {
      final houseNumber = getHouseOfPlanet(p.longitude, houses);
      return PlanetPosition(
        planet: p.planet,
        longitude: p.longitude,
        sign: p.sign,
        degree: p.degree,
        minute: p.minute,
        house: houseNumber,
      );
    }).toList();


    // 6. Рассчитываем аспекты
    List<Aspect> aspects = calculateAspects(updatedPlanetPositions, aspectsOrb);

    // 7. Создаем объект NatalChart
    return NatalChart(
      name: name,
      birthDateTime: birthDateTime,
      birthPlace: birthPlace,
      latitude: latitude,
      longitude: longitude,
      planetPositions: updatedPlanetPositions,
      houses: houses,
      aspects: aspects,
    );
  }
}