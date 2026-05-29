import 'dart:convert';

import 'package:flutter/services.dart';

const String homeSceneLayoutAsset =
    'assets/images/ui/home/home_scene_layout.json';
const String homePetPositionsAsset =
    'assets/images/ui/home/home_pet_positions.json';

class HomeSceneLayout {
  const HomeSceneLayout({required this.profiles, required this.regions});

  final Map<String, HomeSceneLayoutProfile> profiles;
  final Map<String, HomeSceneLayoutRect> regions;

  static Future<HomeSceneLayout> load({bool bypassCache = false}) async {
    final jsonText = await rootBundle.loadString(
      homeSceneLayoutAsset,
      cache: !bypassCache,
    );
    final payload = jsonDecode(jsonText);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Home scene layout root must be an object.');
    }
    return HomeSceneLayout.fromJson(payload);
  }

  factory HomeSceneLayout.fromJson(Map<String, dynamic> json) {
    final profilesJson = _readMap(json, 'profiles');
    final regionsJson = _readMap(json, 'regions');
    return HomeSceneLayout(
      profiles: profilesJson.map(
        (key, value) => MapEntry(
          key,
          HomeSceneLayoutProfile.fromJson(_asObject(value, 'profiles.$key')),
        ),
      ),
      regions: regionsJson.map(
        (key, value) => MapEntry(
          key,
          HomeSceneLayoutRect.fromJson(_asObject(value, 'regions.$key')),
        ),
      ),
    );
  }

  HomeSceneLayoutRect? sprite(String profile, String id) {
    return profiles[profile]?.sprites[id];
  }

  HomeSceneLayoutRect? region(String id) {
    return regions[id];
  }
}

class HomeSceneLayoutProfile {
  const HomeSceneLayoutProfile({required this.sprites});

  final Map<String, HomeSceneLayoutRect> sprites;

  factory HomeSceneLayoutProfile.fromJson(Map<String, dynamic> json) {
    final spritesJson = _readMap(json, 'sprites');
    return HomeSceneLayoutProfile(
      sprites: spritesJson.map(
        (key, value) => MapEntry(
          key,
          HomeSceneLayoutRect.fromJson(_asObject(value, 'sprites.$key')),
        ),
      ),
    );
  }
}

class HomeSceneLayoutRect {
  const HomeSceneLayoutRect({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
  });

  final double centerX;
  final double centerY;
  final double width;
  final double height;

  factory HomeSceneLayoutRect.fromJson(Map<String, dynamic> json) {
    return HomeSceneLayoutRect(
      centerX: _readDouble(json, 'centerX'),
      centerY: _readDouble(json, 'centerY'),
      width: _readDouble(json, 'width'),
      height: _readDouble(json, 'height'),
    );
  }
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw FormatException('Home scene layout "$key" must be an object.');
}

Map<String, dynamic> _asObject(Object? value, String path) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw FormatException('Home scene layout "$path" must be an object.');
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Home scene layout "$key" must be a number.');
}

class HomePetPositions {
  const HomePetPositions({
    required this.candidates,
    required this.assignmentOrder,
  });

  final List<HomePetCandidatePosition> candidates;
  final List<int> assignmentOrder;

  static Future<HomePetPositions> load({bool bypassCache = false}) async {
    final jsonText = await rootBundle.loadString(
      homePetPositionsAsset,
      cache: !bypassCache,
    );
    final payload = jsonDecode(jsonText);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Home pet positions root must be an object.');
    }
    return HomePetPositions.fromJson(payload);
  }

  factory HomePetPositions.fromJson(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    if (candidates is! List) {
      throw const FormatException(
        'Home pet positions "candidates" must be a list.',
      );
    }
    final assignmentOrder = json['assignmentOrder'];
    return HomePetPositions(
      candidates: List<HomePetCandidatePosition>.unmodifiable(
        candidates.indexed.map(
          (entry) => HomePetCandidatePosition.fromJson(
            _asObject(entry.$2, 'candidates.${entry.$1}'),
          ),
        ),
      ),
      assignmentOrder: assignmentOrder is List
          ? List<int>.unmodifiable(assignmentOrder.whereType<int>())
          : const <int>[],
    );
  }
}

class HomePetCandidatePosition {
  const HomePetCandidatePosition({
    this.name,
    required this.centerX,
    required this.centerY,
    required this.widthScale,
    required this.heightScale,
    required this.preferRestPose,
    required this.preferSitPose,
    required this.placementEnabled,
    this.renderPriority,
    this.contactShadow,
  });

  final String? name;
  final double centerX;
  final double centerY;
  final double widthScale;
  final double heightScale;
  final bool preferRestPose;
  final bool preferSitPose;
  final bool placementEnabled;
  final int? renderPriority;
  final HomePetContactShadowPosition? contactShadow;

  factory HomePetCandidatePosition.fromJson(Map<String, dynamic> json) {
    final contactShadowJson = json['contactShadow'];
    return HomePetCandidatePosition(
      name: json['name']?.toString(),
      centerX: _readDouble(json, 'centerX'),
      centerY: _readDouble(json, 'centerY'),
      widthScale: _readOptionalDouble(json, 'widthScale', 1),
      heightScale: _readOptionalDouble(json, 'heightScale', 1),
      preferRestPose: _readOptionalBool(json, 'preferRestPose'),
      preferSitPose: _readOptionalBool(json, 'preferSitPose'),
      placementEnabled: _readOptionalBool(
        json,
        'placementEnabled',
        fallback: true,
      ),
      renderPriority: _readOptionalInt(json, 'renderPriority'),
      contactShadow: contactShadowJson == null
          ? null
          : HomePetContactShadowPosition.fromJson(
              _asObject(contactShadowJson, 'contactShadow'),
            ),
    );
  }
}

class HomePetContactShadowPosition {
  const HomePetContactShadowPosition({
    required this.widthFactor,
    required this.heightFactor,
    required this.centerYFactor,
    required this.opacity,
    required this.blurSigmaFactor,
  });

  final double widthFactor;
  final double heightFactor;
  final double centerYFactor;
  final double opacity;
  final double blurSigmaFactor;

  factory HomePetContactShadowPosition.fromJson(Map<String, dynamic> json) {
    return HomePetContactShadowPosition(
      widthFactor: _readDouble(json, 'widthFactor'),
      heightFactor: _readDouble(json, 'heightFactor'),
      centerYFactor: _readDouble(json, 'centerYFactor'),
      opacity: _readOptionalDouble(json, 'opacity', 0.18),
      blurSigmaFactor: _readOptionalDouble(json, 'blurSigmaFactor', 0.06),
    );
  }
}

double _readOptionalDouble(
  Map<String, dynamic> json,
  String key,
  double fallback,
) {
  final value = json[key];
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Home scene layout "$key" must be a number.');
}

int? _readOptionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw FormatException('Home scene layout "$key" must be an integer.');
}

bool _readOptionalBool(
  Map<String, dynamic> json,
  String key, {
  bool fallback = false,
}) {
  final value = json[key];
  if (value == null) {
    return fallback;
  }
  if (value is bool) {
    return value;
  }
  throw FormatException('Home scene layout "$key" must be a boolean.');
}
