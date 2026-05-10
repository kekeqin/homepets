import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class SpriteAtlasAsset {
  const SpriteAtlasAsset({
    required this.imageAsset,
    required this.metadataAsset,
  });

  final String imageAsset;
  final String metadataAsset;

  static final Map<String, Future<SpriteAtlas>> _rootBundleCache =
      <String, Future<SpriteAtlas>>{};

  String get flameImageAsset => imageAsset.startsWith('assets/')
      ? imageAsset.substring('assets/'.length)
      : imageAsset;

  Future<SpriteAtlas> load({AssetBundle? bundle}) {
    final resolvedBundle = bundle ?? rootBundle;
    if (!identical(resolvedBundle, rootBundle)) {
      return _loadFromBundle(resolvedBundle);
    }

    final cacheKey = '$imageAsset|$metadataAsset';
    return _rootBundleCache.putIfAbsent(
      cacheKey,
      () => _loadFromBundle(resolvedBundle),
    );
  }

  Future<SpriteAtlas> _loadFromBundle(AssetBundle bundle) async {
    final json = await bundle.loadString(metadataAsset);
    return SpriteAtlas.fromJsonString(
      json,
      imageAsset: imageAsset,
      metadataAsset: metadataAsset,
    );
  }
}

class SpriteAtlas {
  const SpriteAtlas({
    required this.imageAsset,
    required this.metadataAsset,
    required this.sheetSize,
    required Map<String, SpriteAtlasFrame> frames,
  }) : _frames = frames;

  final String imageAsset;
  final String metadataAsset;
  final Size sheetSize;
  final Map<String, SpriteAtlasFrame> _frames;

  Iterable<String> get frameNames => _frames.keys;

  SpriteAtlasFrame frame(String name) {
    final frame = _frames[name];
    if (frame == null) {
      throw ArgumentError.value(
        name,
        'name',
        'Frame not found in atlas $metadataAsset.',
      );
    }
    return frame;
  }

  SpriteAtlasFrame? maybeFrame(String name) => _frames[name];

  factory SpriteAtlas.fromJsonString(
    String rawJson, {
    required String imageAsset,
    required String metadataAsset,
  }) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Sprite atlas JSON must be an object.');
    }

    final root = Map<String, Object?>.from(decoded);
    final rawFrames = root['frames'];
    if (rawFrames is! Map) {
      throw const FormatException(
        'Sprite atlas JSON must contain a frames map.',
      );
    }

    final frames = <String, SpriteAtlasFrame>{};
    for (final entry in rawFrames.entries) {
      final value = entry.value;
      if (value is! Map) {
        throw FormatException(
          'Sprite atlas frame ${entry.key} must be a JSON object.',
        );
      }

      final frameName = entry.key.toString();
      frames[frameName] = SpriteAtlasFrame.fromJson(
        frameName,
        Map<String, Object?>.from(value),
      );
    }

    final sheetSize = _readAtlasSize(root, frames.values);

    return SpriteAtlas(
      imageAsset: imageAsset,
      metadataAsset: metadataAsset,
      sheetSize: sheetSize,
      frames: Map<String, SpriteAtlasFrame>.unmodifiable(frames),
    );
  }
}

class SpriteAtlasFrame {
  const SpriteAtlasFrame({
    required this.name,
    required this.textureRect,
    required this.sourceRect,
    required this.sourceSize,
    required this.rotated,
    required this.trimmed,
  });

  final String name;
  final Rect textureRect;
  final Rect sourceRect;
  final Size sourceSize;
  final bool rotated;
  final bool trimmed;

  double get aspectRatio {
    final normalized = normalizedSourceSize;
    if (normalized.height == 0) {
      return 1;
    }
    return normalized.width / normalized.height;
  }

  Size get normalizedSourceSize {
    final width = sourceSize.width <= 0 ? textureRect.width : sourceSize.width;
    final height = sourceSize.height <= 0
        ? textureRect.height
        : sourceSize.height;
    return Size(width, height);
  }

  factory SpriteAtlasFrame.fromJson(String name, Map<String, Object?> json) {
    final textureRect = _readRect(json['frame'], context: '$name.frame');
    final fallbackSourceRect = Rect.fromLTWH(
      0,
      0,
      textureRect.width,
      textureRect.height,
    );
    final sourceRect = _readRect(
      json['spriteSourceSize'],
      context: '$name.spriteSourceSize',
      fallback: fallbackSourceRect,
    );
    final sourceSize = _readSize(
      json['sourceSize'],
      context: '$name.sourceSize',
      fallback: textureRect.size,
    );

    return SpriteAtlasFrame(
      name: name,
      textureRect: textureRect,
      sourceRect: sourceRect,
      sourceSize: sourceSize,
      rotated: _readBool(json['rotated']),
      trimmed: _readBool(json['trimmed']),
    );
  }
}

class SpriteFrameImage extends StatelessWidget {
  const SpriteFrameImage({
    super.key,
    required this.imageAsset,
    required this.frame,
    this.sheetSize,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
    this.filterQuality = FilterQuality.high,
    this.sampleInset = 0,
  });

  final String imageAsset;
  final SpriteAtlasFrame frame;
  final Size? sheetSize;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final BlendMode colorBlendMode;
  final FilterQuality filterQuality;
  final double sampleInset;

  @override
  Widget build(BuildContext context) {
    final sourceSize = frame.normalizedSourceSize;
    final resolvedSheetSize =
        sheetSize ?? Size(frame.textureRect.right, frame.textureRect.bottom);
    final resolvedSampleInset = _resolveSpriteSampleInset(frame, sampleInset);
    final textureRect = resolvedSampleInset <= 0
        ? frame.textureRect
        : frame.textureRect.deflate(resolvedSampleInset);
    final sourceDrawRect =
        frame.sourceRect.width <= 0 || frame.sourceRect.height <= 0
        ? Offset.zero & sourceSize
        : frame.sourceRect;
    final textureScaleX = sourceDrawRect.width / textureRect.width;
    final textureScaleY = sourceDrawRect.height / textureRect.height;
    return FittedBox(
      fit: fit,
      alignment: alignment,
      child: SizedBox(
        width: sourceSize.width,
        height: sourceSize.height,
        child: ClipRect(
          child: OverflowBox(
            minWidth: resolvedSheetSize.width * textureScaleX,
            maxWidth: resolvedSheetSize.width * textureScaleX,
            minHeight: resolvedSheetSize.height * textureScaleY,
            maxHeight: resolvedSheetSize.height * textureScaleY,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(
                (-textureRect.left * textureScaleX) + sourceDrawRect.left,
                (-textureRect.top * textureScaleY) + sourceDrawRect.top,
              ),
              child: Image.asset(
                imageAsset,
                width: resolvedSheetSize.width * textureScaleX,
                height: resolvedSheetSize.height * textureScaleY,
                fit: BoxFit.fill,
                alignment: Alignment.topLeft,
                filterQuality: filterQuality,
                color: color,
                colorBlendMode: color == null ? null : colorBlendMode,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _resolveSpriteSampleInset(
  SpriteAtlasFrame frame,
  double requestedInset,
) {
  if (requestedInset <= 0) {
    return 0;
  }

  final sourceDrawWidth = frame.sourceRect.width <= 0
      ? frame.normalizedSourceSize.width
      : frame.sourceRect.width;
  final sourceDrawHeight = frame.sourceRect.height <= 0
      ? frame.normalizedSourceSize.height
      : frame.sourceRect.height;
  final shortestDrawableSide = math.min(
    math.min(frame.textureRect.width, frame.textureRect.height),
    math.min(sourceDrawWidth, sourceDrawHeight),
  );
  final maxInset = (shortestDrawableSide / 2) - 0.5;
  if (maxInset <= 0) {
    return 0;
  }

  return requestedInset.clamp(0.0, maxInset).toDouble();
}

Size _readAtlasSize(
  Map<String, Object?> root,
  Iterable<SpriteAtlasFrame> frames,
) {
  final rawMeta = root['meta'];
  if (rawMeta is Map) {
    final meta = Map<String, Object?>.from(rawMeta);
    final rawSize = meta['size'];
    if (rawSize is Map) {
      return _readSize(
        rawSize,
        context: 'meta.size',
        fallback: const Size(1, 1),
      );
    }
  }

  var maxRight = 0.0;
  var maxBottom = 0.0;
  for (final frame in frames) {
    if (frame.textureRect.right > maxRight) {
      maxRight = frame.textureRect.right;
    }
    if (frame.textureRect.bottom > maxBottom) {
      maxBottom = frame.textureRect.bottom;
    }
  }

  return Size(maxRight, maxBottom);
}

Rect _readRect(Object? value, {required String context, Rect? fallback}) {
  if (value == null) {
    if (fallback != null) {
      return fallback;
    }
    throw FormatException('Missing rect value for $context.');
  }
  if (value is! Map) {
    throw FormatException('Rect value for $context must be a JSON object.');
  }

  final map = Map<String, Object?>.from(value);
  return Rect.fromLTWH(
    _readDouble(map, const <String>['x', 'left'], context: '$context.x'),
    _readDouble(map, const <String>['y', 'top'], context: '$context.y'),
    _readDouble(map, const <String>['w', 'width'], context: '$context.width'),
    _readDouble(map, const <String>['h', 'height'], context: '$context.height'),
  );
}

Size _readSize(
  Object? value, {
  required String context,
  required Size fallback,
}) {
  if (value == null) {
    return fallback;
  }
  if (value is! Map) {
    throw FormatException('Size value for $context must be a JSON object.');
  }

  final map = Map<String, Object?>.from(value);
  return Size(
    _readDouble(map, const <String>['w', 'width'], context: '$context.width'),
    _readDouble(map, const <String>['h', 'height'], context: '$context.height'),
  );
}

double _readDouble(
  Map<String, Object?> map,
  List<String> keys, {
  required String context,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  throw FormatException('Unable to parse numeric value for $context.');
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }
  return false;
}
