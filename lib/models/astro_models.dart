// lib/models/astro_models.dart

// Знаки зодиака
enum ZodiacSign {
  aries('Овен', '♈'),
  taurus('Телец', '♉'),
  gemini('Близнецы', '♊'),
  cancer('Рак', '♋'),
  leo('Лев', '♌'),
  virgo('Дева', '♍'),
  libra('Весы', '♎'),
  scorpio('Скорпион', '♏'),
  sagittarius('Стрелец', '♐'),
  capricorn('Козерог', '♑'),
  aquarius('Водолей', '♒'),
  pisces('Рыбы', '♓');

  final String label;
  final String symbol;

  const ZodiacSign(this.label, this.symbol);

  // Метод для сериализации в Map
  Map<String, dynamic> toMap() => {
    'label': label,
    'symbol': symbol,
    'name': name, // Добавляем имя enum для более легкой десериализации
  };

  // Фабричный конструктор для десериализации из Map
  factory ZodiacSign.fromMap(Map<String, dynamic> map) {
    // Ищем enum по имени, которое мы добавили в toMap
    return ZodiacSign.values.firstWhere(
      (e) => e.name == map['name'],
      orElse: () => throw ArgumentError('Unknown ZodiacSign name: ${map['name']}'),
    );
  }

  // Также можно добавить методы для поиска по label или symbol, если это требуется
  factory ZodiacSign.fromLabel(String label) {
    return ZodiacSign.values.firstWhere(
      (e) => e.label == label,
      orElse: () => throw ArgumentError('Unknown ZodiacSign label: $label'),
    );
  }

  factory ZodiacSign.fromSymbol(String symbol) {
    return ZodiacSign.values.firstWhere(
      (e) => e.symbol == symbol,
      orElse: () => throw ArgumentError('Unknown ZodiacSign symbol: $symbol'),
    );
  }
}

// Планеты
enum Planet {
  sun('Солнце', '☉'),
  moon('Луна', '☽'),
  mercury('Меркурий', '☿'),
  venus('Венера', '♀'),
  mars('Марс', '♂'),
  jupiter('Юпитер', '♃'),
  saturn('Сатурн', '♄'),
  uranus('Уран', '♅'),
  neptune('Нептун', '♆'),
  pluto('Плутон', '♇');

  final String label;
  final String symbol;

  const Planet(this.label, this.symbol);

  // Метод для сериализации в Map
  Map<String, dynamic> toMap() => {
    'label': label,
    'symbol': symbol,
    'name': name, // Добавляем имя enum для более легкой десериализации
  };

  // Фабричный конструктор для десериализации из Map
  factory Planet.fromMap(Map<String, dynamic> map) {
    return Planet.values.firstWhere(
      (e) => e.name == map['name'],
      orElse: () => throw ArgumentError('Unknown Planet name: ${map['name']}'),
    );
  }

  factory Planet.fromLabel(String label) {
    return Planet.values.firstWhere(
      (e) => e.label == label,
      orElse: () => throw ArgumentError('Unknown Planet label: $label'),
    );
  }

  factory Planet.fromSymbol(String symbol) {
    return Planet.values.firstWhere(
      (e) => e.symbol == symbol,
      orElse: () => throw ArgumentError('Unknown Planet symbol: $symbol'),
    );
  }
}

// Дома
class House {
  final int number;
  final double cusp;
  final ZodiacSign sign;

  House({
    required this.number,
    required this.cusp,
    required this.sign,
  });

  // Метод для сериализации в Map
  Map<String, dynamic> toMap() => {
    'number': number,
    'cusp': cusp,
    'sign': sign.toMap(), // Рекурсивный вызов toMap для вложенного объекта
  };

  // Фабричный конструктор для десериализации из Map
  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      number: map['number'] as int,
      cusp: map['cusp'] as double,
      sign: ZodiacSign.fromMap(map['sign'] as Map<String, dynamic>),
    );
  }
}

// Положение планеты
class PlanetPosition {
  final Planet planet;
  final double longitude;
  final ZodiacSign sign;
  final int degree;
  final int minute;
  final int house;

  PlanetPosition({
    required this.planet,
    required this.longitude,
    required this.sign,
    required this.degree,
    required this.minute,
    required this.house,
  });

  // Метод для сериализации в Map
  Map<String, dynamic> toMap() => {
    'planet': planet.toMap(),
    'longitude': longitude,
    'sign': sign.toMap(),
    'degree': degree,
    'minute': minute,
    'house': house,
  };

  // Фабричный конструктор для десериализации из Map
  factory PlanetPosition.fromMap(Map<String, dynamic> map) {
    return PlanetPosition(
      planet: Planet.fromMap(map['planet'] as Map<String, dynamic>),
      longitude: map['longitude'] as double,
      sign: ZodiacSign.fromMap(map['sign'] as Map<String, dynamic>),
      degree: map['degree'] as int,
      minute: map['minute'] as int,
      house: map['house'] as int,
    );
  }
}

// Аспекты
enum AspectType {
  conjunction('Соединение', 0, '☌'),
  sextile('Секстиль', 60, '⚹'),
  square('Квадрат', 90, '□'),
  trine('Трин', 120, '△'),
  opposition('Оппозиция', 180, '☍');

  final String label;
  final double angle;
  final String symbol;

  const AspectType(this.label, this.angle, this.symbol);

  // Метод для сериализации в Map
  Map<String, dynamic> toMap() => {
    'label': label,
    'angle': angle,
    'symbol': symbol,
    'name': name, // Добавляем имя enum для более легкой десериализации
  };

  // Фабричный конструктор для десериализации из Map
  factory AspectType.fromMap(Map<String, dynamic> map) {
    return AspectType.values.firstWhere(
      (e) => e.name == map['name'],
      orElse: () => throw ArgumentError('Unknown AspectType name: ${map['name']}'),
    );
  }

  factory AspectType.fromLabel(String label) {
    return AspectType.values.firstWhere(
      (e) => e.label == label,
      orElse: () => throw ArgumentError('Unknown AspectType label: $label'),
    );
  }

  factory AspectType.fromSymbol(String symbol) {
    return AspectType.values.firstWhere(
      (e) => e.symbol == symbol,
      orElse: () => throw ArgumentError('Unknown AspectType symbol: $symbol'),
    );
  }
}

class Aspect {
  final Planet planet1;
  final Planet planet2;
  final AspectType type;
  final double orb;

  Aspect({
    required this.planet1,
    required this.planet2,
    required this.type,
    required this.orb,
  });

  // Метод для сериализации в Map
  Map<String, dynamic> toMap() => {
    'planet1': planet1.toMap(),
    'planet2': planet2.toMap(),
    'type': type.toMap(),
    'orb': orb,
  };

  // Фабричный конструктор для десериализации из Map
  factory Aspect.fromMap(Map<String, dynamic> map) {
    return Aspect(
      planet1: Planet.fromMap(map['planet1'] as Map<String, dynamic>),
      planet2: Planet.fromMap(map['planet2'] as Map<String, dynamic>),
      type: AspectType.fromMap(map['type'] as Map<String, dynamic>),
      orb: map['orb'] as double,
    );
  }
}

// Натальная карта
class NatalChart {
  final String name;
  final DateTime birthDateTime;
  final String birthPlace;
  final double latitude;
  final double longitude;
  final List<PlanetPosition> planetPositions;
  final List<House> houses;
  final List<Aspect> aspects;

  NatalChart({
    required this.name,
    required this.birthDateTime,
    required this.birthPlace,
    required this.latitude,
    required this.longitude,
    required this.planetPositions,
    required this.houses,
    required this.aspects,
  });

  // Метод для сериализации в JSON-совместимый Map
  Map<String, dynamic> toJson() => {
    'name': name,
    'birthDateTime': birthDateTime.toIso8601String(), // Дата в строковом формате
    'birthPlace': birthPlace,
    'latitude': latitude,
    'longitude': longitude,
    'planetPositions': planetPositions.map((p) => p.toMap()).toList(),
    'houses': houses.map((h) => h.toMap()).toList(),
    'aspects': aspects.map((a) => a.toMap()).toList(),
  };

  // Фабричный конструктор для десериализации из JSON-совместимого Map
  factory NatalChart.fromJson(Map<String, dynamic> json) {
    return NatalChart(
      name: json['name'] as String,
      birthDateTime: DateTime.parse(json['birthDateTime'] as String), // Парсим строку обратно в DateTime
      birthPlace: json['birthPlace'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      planetPositions: (json['planetPositions'] as List)
          .map((item) => PlanetPosition.fromMap(item as Map<String, dynamic>))
          .toList(),
      houses: (json['houses'] as List)
          .map((item) => House.fromMap(item as Map<String, dynamic>))
          .toList(),
      aspects: (json['aspects'] as List)
          .map((item) => Aspect.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Координаты
class Coordinates {
  final double latitude;
  final double longitude;
  final String utcOffset; // Например, "+03:00" или "-05:00"

  Coordinates({
    required this.latitude,
    required this.longitude,
    required this.utcOffset,
  });

  // Метод для сериализации в Map
  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'utcOffset': utcOffset,
  };

  // Фабричный конструктор для десериализации из Map
  factory Coordinates.fromMap(Map<String, dynamic> map) {
    return Coordinates(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      utcOffset: map['utcOffset'] as String,
    );
  }
}