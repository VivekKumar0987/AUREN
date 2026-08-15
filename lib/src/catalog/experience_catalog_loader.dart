import 'dart:convert';

import 'package:flutter/services.dart';

import 'experience.dart';

class ExperienceCatalogLoader {
  const ExperienceCatalogLoader({this.assetPath = _defaultAssetPath});

  static const String _defaultAssetPath = 'AUREN_Strong_160_Experiences.json';

  final String assetPath;

  Future<ExperienceCatalog> load({AssetBundle? bundle}) async {
    final assetBundle = bundle ?? rootBundle;
    final raw = await assetBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('AUREN catalog root must be a JSON object.');
    }

    final rawExperiences = decoded['experiences'];
    if (rawExperiences is! List) {
      throw const FormatException('AUREN catalog must contain experiences.');
    }

    return ExperienceCatalog(
      app: decoded['app']?.toString() ?? 'AUREN',
      declaredCount: _readInt(decoded['count']),
      note: decoded['note']?.toString() ?? '',
      experiences: rawExperiences
          .whereType<Map>()
          .map((item) => Experience.fromJson(item.cast<String, Object?>()))
          .toList(growable: false),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
