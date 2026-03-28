import 'package:flutter/material.dart';

class QWeatherIcons {
  QWeatherIcons._();

  static const String fontFamily = 'QWeatherIcons';
  static const Color coldColor = Color.fromARGB(255, 131, 131, 131);
  static const Color warmColor = Color(0xFFFEBD14);

  static const Map<String, int> _codePoints = {
    "100": 61697,
    "100-fill": 61900,
    "101": 61698,
    "101-fill": 61901,
    "102": 61699,
    "102-fill": 61902,
    "103": 61700,
    "103-fill": 61903,
    "104": 61701,
    "104-fill": 61904,
    "150": 61702,
    "150-fill": 61905,
    "151": 61703,
    "151-fill": 61906,
    "152": 61704,
    "152-fill": 61907,
    "153": 61705,
    "153-fill": 61908,
    "300": 61706,
    "300-fill": 61909,
    "301": 61707,
    "301-fill": 61910,
    "302": 61708,
    "302-fill": 61911,
    "303": 61709,
    "303-fill": 61912,
    "304": 61710,
    "304-fill": 61913,
    "305": 61711,
    "305-fill": 61914,
    "306": 61712,
    "306-fill": 61915,
    "307": 61713,
    "307-fill": 61916,
    "308": 61714,
    "308-fill": 61917,
    "309": 61715,
    "309-fill": 61918,
    "310": 61716,
    "310-fill": 61919,
    "311": 61717,
    "311-fill": 61920,
    "312": 61718,
    "312-fill": 61921,
    "313": 61719,
    "313-fill": 61922,
    "314": 61720,
    "314-fill": 61923,
    "315": 61721,
    "315-fill": 61924,
    "316": 61722,
    "316-fill": 61925,
    "317": 61723,
    "317-fill": 61926,
    "318": 61724,
    "318-fill": 61927,
    "350": 61725,
    "350-fill": 61928,
    "351": 61726,
    "351-fill": 61929,
    "399": 61727,
    "399-fill": 61930,
    "400": 61728,
    "400-fill": 61931,
    "401": 61729,
    "401-fill": 61932,
    "402": 61730,
    "402-fill": 61933,
    "403": 61731,
    "403-fill": 61934,
    "404": 61732,
    "404-fill": 61935,
    "405": 61733,
    "405-fill": 61936,
    "406": 61734,
    "406-fill": 61937,
    "407": 61735,
    "407-fill": 61938,
    "408": 61736,
    "408-fill": 61939,
    "409": 61737,
    "409-fill": 61940,
    "410": 61738,
    "410-fill": 61941,
    "456": 61739,
    "456-fill": 61942,
    "457": 61740,
    "457-fill": 61943,
    "499": 61741,
    "499-fill": 61944,
    "500": 61742,
    "500-fill": 61945,
    "501": 61743,
    "501-fill": 61946,
    "502": 61744,
    "502-fill": 61947,
    "503": 61745,
    "503-fill": 61948,
    "504": 61746,
    "504-fill": 61949,
    "507": 61747,
    "507-fill": 61950,
    "508": 61748,
    "508-fill": 61951,
    "509": 61749,
    "509-fill": 61952,
    "510": 61750,
    "510-fill": 61953,
    "511": 61751,
    "511-fill": 61954,
    "512": 61752,
    "512-fill": 61955,
    "513": 61753,
    "513-fill": 61956,
    "514": 61754,
    "514-fill": 61957,
    "515": 61755,
    "515-fill": 61958,
    "800": 61756,
    "801": 61757,
    "802": 61758,
    "803": 61759,
    "804": 61760,
    "805": 61761,
    "806": 61762,
    "807": 61763,
    "900": 61764,
    "900-fill": 61959,
    "901": 61765,
    "901-fill": 61960,
    "999": 61766,
    "999-fill": 61961,
    "wind": 61978,
    "low-humidity2": 62006,
  };

  static IconData? resolve(String? icon, {bool fill = false}) {
    final normalized = icon?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final key = fill && !normalized.endsWith('-fill')
        ? '$normalized-fill'
        : normalized;
    final codePoint = _codePoints[key] ?? _codePoints[normalized];

    if (codePoint == null) {
      return null;
    }

    return IconData(codePoint, fontFamily: fontFamily);
  }

  static Color colorFor(String? icon) {
    final normalized = icon?.trim();
    if (normalized == null || normalized.isEmpty) {
      return warmColor;
    }

    switch (normalized) {
      case 'wind':
      case 'wind2':
      case 'low-humidity2':
        return coldColor;
    }

    final baseCode = int.tryParse(normalized.replaceAll('-fill', ''));
    if (baseCode == null) {
      return warmColor;
    }

    return _isWarmWeather(baseCode) ? warmColor : coldColor;
  }

  static bool _isWarmWeather(int code) =>
      (code >= 100 && code <= 104) || (code >= 150 && code <= 153);
}

class QWeatherIcon extends StatelessWidget {
  const QWeatherIcon({
    super.key,
    required this.icon,
    this.fill = false,
    this.size,
    this.color,
    this.fallback,
  });

  final String? icon;
  final bool fill;
  final double? size;
  final Color? color;
  final IconData? fallback;

  @override
  Widget build(BuildContext context) {
    final resolved = QWeatherIcons.resolve(icon, fill: fill) ?? fallback;
    final resolvedColor = color ?? QWeatherIcons.colorFor(icon);

    return Icon(
      resolved ?? Icons.help_outline_rounded,
      size: size,
      color: resolvedColor,
    );
  }
}
