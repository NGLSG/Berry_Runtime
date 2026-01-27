import 'dart:ui';

/// Audio resource types
enum AudioType {
  bgm,
  sfx,
  voice,
  ambient,
}

/// Video resource for backgrounds and cutscenes
class VNVideo {
  /// Unique identifier
  final String id;

  /// File path relative to project
  final String path;

  /// Thumbnail path (generated from first frame)
  final String? thumbnailPath;

  /// Video duration
  final Duration duration;

  /// Video resolution
  final Size resolution;

  /// Display name
  final String? displayName;

  /// Tags for organization
  final List<String> tags;

  /// Whether this video should loop by default
  final bool defaultLoop;

  /// Whether this video should be muted by default
  final bool defaultMuted;

  const VNVideo({
    required this.id,
    required this.path,
    this.thumbnailPath,
    this.duration = Duration.zero,
    this.resolution = Size.zero,
    this.displayName,
    this.tags = const [],
    this.defaultLoop = true,
    this.defaultMuted = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        'duration': duration.inMilliseconds,
        'resolution': {
          'width': resolution.width,
          'height': resolution.height,
        },
        if (displayName != null) 'displayName': displayName,
        if (tags.isNotEmpty) 'tags': tags,
        'defaultLoop': defaultLoop,
        'defaultMuted': defaultMuted,
      };

  factory VNVideo.fromJson(Map<String, dynamic> json) {
    final resJson = json['resolution'] as Map<String, dynamic>?;
    return VNVideo(
      id: json['id'] as String,
      path: json['path'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      resolution: resJson != null
          ? Size(
              (resJson['width'] as num).toDouble(),
              (resJson['height'] as num).toDouble(),
            )
          : Size.zero,
      displayName: json['displayName'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      defaultLoop: json['defaultLoop'] as bool? ?? true,
      defaultMuted: json['defaultMuted'] as bool? ?? true,
    );
  }

  VNVideo copyWith({
    String? id,
    String? path,
    String? thumbnailPath,
    Duration? duration,
    Size? resolution,
    String? displayName,
    List<String>? tags,
    bool? defaultLoop,
    bool? defaultMuted,
  }) {
    return VNVideo(
      id: id ?? this.id,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
      resolution: resolution ?? this.resolution,
      displayName: displayName ?? this.displayName,
      tags: tags ?? this.tags,
      defaultLoop: defaultLoop ?? this.defaultLoop,
      defaultMuted: defaultMuted ?? this.defaultMuted,
    );
  }
}

/// Background resource
class VNBackground {
  /// Unique identifier
  final String id;

  /// File path relative to project
  final String path;

  /// Thumbnail path (generated)
  final String? thumbnailPath;

  /// Original image size
  final Size originalSize;

  /// Display name
  final String? displayName;

  /// Tags for organization
  final List<String> tags;

  const VNBackground({
    required this.id,
    required this.path,
    this.thumbnailPath,
    this.originalSize = Size.zero,
    this.displayName,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        'originalSize': {
          'width': originalSize.width,
          'height': originalSize.height,
        },
        if (displayName != null) 'displayName': displayName,
        if (tags.isNotEmpty) 'tags': tags,
      };

  factory VNBackground.fromJson(Map<String, dynamic> json) {
    final sizeJson = json['originalSize'] as Map<String, dynamic>?;
    return VNBackground(
      id: json['id'] as String,
      path: json['path'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      originalSize: sizeJson != null
          ? Size(
              (sizeJson['width'] as num).toDouble(),
              (sizeJson['height'] as num).toDouble(),
            )
          : Size.zero,
      displayName: json['displayName'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  VNBackground copyWith({
    String? id,
    String? path,
    String? thumbnailPath,
    Size? originalSize,
    String? displayName,
    List<String>? tags,
  }) {
    return VNBackground(
      id: id ?? this.id,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      originalSize: originalSize ?? this.originalSize,
      displayName: displayName ?? this.displayName,
      tags: tags ?? this.tags,
    );
  }
}

/// Audio resource (BGM, SFX, Voice)
class VNAudio {
  /// Unique identifier
  final String id;

  /// File path relative to project
  final String path;

  /// Audio duration
  final Duration duration;

  /// Audio type
  final AudioType type;

  /// Display name
  final String? displayName;

  /// Tags for organization
  final List<String> tags;

  /// Whether this audio should loop by default
  final bool defaultLoop;

  const VNAudio({
    required this.id,
    required this.path,
    this.duration = Duration.zero,
    required this.type,
    this.displayName,
    this.tags = const [],
    this.defaultLoop = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'duration': duration.inMilliseconds,
        'type': type.name,
        if (displayName != null) 'displayName': displayName,
        if (tags.isNotEmpty) 'tags': tags,
        'defaultLoop': defaultLoop,
      };

  factory VNAudio.fromJson(Map<String, dynamic> json) {
    return VNAudio(
      id: json['id'] as String,
      path: json['path'] as String,
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      type: AudioType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AudioType.sfx,
      ),
      displayName: json['displayName'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      defaultLoop: json['defaultLoop'] as bool? ?? false,
    );
  }

  VNAudio copyWith({
    String? id,
    String? path,
    Duration? duration,
    AudioType? type,
    String? displayName,
    List<String>? tags,
    bool? defaultLoop,
  }) {
    return VNAudio(
      id: id ?? this.id,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      tags: tags ?? this.tags,
      defaultLoop: defaultLoop ?? this.defaultLoop,
    );
  }
}


/// Image resource (CG, UI elements)
class VNImage {
  /// Unique identifier
  final String id;

  /// File path relative to project
  final String path;

  /// Thumbnail path (generated)
  final String? thumbnailPath;

  /// Original image size
  final Size originalSize;

  /// Display name
  final String? displayName;

  /// Tags for organization
  final List<String> tags;

  /// Whether this is a gallery-unlockable CG
  final bool isGalleryCG;
  
  /// Alt-text description for accessibility (Requirements 10.8)
  /// Used by screen readers to describe the image content
  final String? altText;

  const VNImage({
    required this.id,
    required this.path,
    this.thumbnailPath,
    this.originalSize = Size.zero,
    this.displayName,
    this.tags = const [],
    this.isGalleryCG = false,
    this.altText,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        'originalSize': {
          'width': originalSize.width,
          'height': originalSize.height,
        },
        if (displayName != null) 'displayName': displayName,
        if (tags.isNotEmpty) 'tags': tags,
        'isGalleryCG': isGalleryCG,
        if (altText != null) 'altText': altText,
      };

  factory VNImage.fromJson(Map<String, dynamic> json) {
    final sizeJson = json['originalSize'] as Map<String, dynamic>?;
    return VNImage(
      id: json['id'] as String,
      path: json['path'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      originalSize: sizeJson != null
          ? Size(
              (sizeJson['width'] as num).toDouble(),
              (sizeJson['height'] as num).toDouble(),
            )
          : Size.zero,
      displayName: json['displayName'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      isGalleryCG: json['isGalleryCG'] as bool? ?? false,
      altText: json['altText'] as String?,
    );
  }

  VNImage copyWith({
    String? id,
    String? path,
    String? thumbnailPath,
    Size? originalSize,
    String? displayName,
    List<String>? tags,
    bool? isGalleryCG,
    String? altText,
    bool clearAltText = false,
  }) {
    return VNImage(
      id: id ?? this.id,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      originalSize: originalSize ?? this.originalSize,
      displayName: displayName ?? this.displayName,
      tags: tags ?? this.tags,
      isGalleryCG: isGalleryCG ?? this.isGalleryCG,
      altText: clearAltText ? null : (altText ?? this.altText),
    );
  }
}

/// Resource library containing all project assets
class VNResourceLibrary {
  /// Background images
  final Map<String, VNBackground> backgrounds;

  /// Background music
  final Map<String, VNAudio> bgm;

  /// Sound effects
  final Map<String, VNAudio> sfx;

  /// Voice files
  final Map<String, VNAudio> voices;

  /// CG and other images
  final Map<String, VNImage> cgs;
  
  /// Video files (for backgrounds, cutscenes)
  final Map<String, VNVideo> videos;

  const VNResourceLibrary({
    this.backgrounds = const {},
    this.bgm = const {},
    this.sfx = const {},
    this.voices = const {},
    this.cgs = const {},
    this.videos = const {},
  });

  Map<String, dynamic> toJson() => {
        'backgrounds': backgrounds.map((k, v) => MapEntry(k, v.toJson())),
        'bgm': bgm.map((k, v) => MapEntry(k, v.toJson())),
        'sfx': sfx.map((k, v) => MapEntry(k, v.toJson())),
        'voices': voices.map((k, v) => MapEntry(k, v.toJson())),
        'cgs': cgs.map((k, v) => MapEntry(k, v.toJson())),
        'videos': videos.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory VNResourceLibrary.fromJson(Map<String, dynamic> json) {
    return VNResourceLibrary(
      backgrounds: (json['backgrounds'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, VNBackground.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
      bgm: (json['bgm'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, VNAudio.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
      sfx: (json['sfx'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, VNAudio.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
      voices: (json['voices'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, VNAudio.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
      cgs: (json['cgs'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, VNImage.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
      videos: (json['videos'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, VNVideo.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
    );
  }

  VNResourceLibrary copyWith({
    Map<String, VNBackground>? backgrounds,
    Map<String, VNAudio>? bgm,
    Map<String, VNAudio>? sfx,
    Map<String, VNAudio>? voices,
    Map<String, VNImage>? cgs,
    Map<String, VNVideo>? videos,
  }) {
    return VNResourceLibrary(
      backgrounds: backgrounds ?? this.backgrounds,
      bgm: bgm ?? this.bgm,
      sfx: sfx ?? this.sfx,
      voices: voices ?? this.voices,
      cgs: cgs ?? this.cgs,
      videos: videos ?? this.videos,
    );
  }

  /// Get a background by ID
  VNBackground? getBackground(String id) => backgrounds[id];

  /// Get BGM by ID
  VNAudio? getBgm(String id) => bgm[id];

  /// Get SFX by ID
  VNAudio? getSfx(String id) => sfx[id];

  /// Get voice by ID
  VNAudio? getVoice(String id) => voices[id];

  /// Get CG by ID
  VNImage? getCg(String id) => cgs[id];
  
  /// Get video by ID
  VNVideo? getVideo(String id) => videos[id];

  /// Check if a background exists
  bool hasBackground(String id) => backgrounds.containsKey(id);

  /// Check if BGM exists
  bool hasBgm(String id) => bgm.containsKey(id);

  /// Check if SFX exists
  bool hasSfx(String id) => sfx.containsKey(id);

  /// Check if voice exists
  bool hasVoice(String id) => voices.containsKey(id);

  /// Check if CG exists
  bool hasCg(String id) => cgs.containsKey(id);
  
  /// Check if video exists
  bool hasVideo(String id) => videos.containsKey(id);

  /// Get total resource count
  int get totalCount =>
      backgrounds.length + bgm.length + sfx.length + voices.length + cgs.length + videos.length;

  /// Validate resource references
  List<String> validateReferences(List<String> backgroundIds, List<String> bgmIds,
      List<String> sfxIds, List<String> voiceIds, List<String> cgIds, [List<String> videoIds = const []]) {
    final errors = <String>[];

    for (final id in backgroundIds) {
      if (!hasBackground(id)) {
        errors.add('Missing background resource: $id');
      }
    }
    for (final id in bgmIds) {
      if (!hasBgm(id)) {
        errors.add('Missing BGM resource: $id');
      }
    }
    for (final id in sfxIds) {
      if (!hasSfx(id)) {
        errors.add('Missing SFX resource: $id');
      }
    }
    for (final id in voiceIds) {
      if (!hasVoice(id)) {
        errors.add('Missing voice resource: $id');
      }
    }
    for (final id in cgIds) {
      if (!hasCg(id)) {
        errors.add('Missing CG resource: $id');
      }
    }
    for (final id in videoIds) {
      if (!hasVideo(id)) {
        errors.add('Missing video resource: $id');
      }
    }

    return errors;
  }
}
