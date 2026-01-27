/// Texture Compression Support
///
/// Provides support for compressed texture formats (WebP, ASTC) to reduce
/// memory usage and improve loading times on mobile devices.
///
/// Requirements: 24.3

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Supported texture compression formats
enum TextureFormat {
  /// Original format (PNG, JPEG)
  original,

  /// WebP format (good compression, wide support)
  webp,

  /// ASTC format (GPU-native, best for mobile)
  astc,

  /// ETC2 format (OpenGL ES 3.0+)
  etc2,

  /// PVRTC format (iOS/PowerVR)
  pvrtc,
}

/// Texture quality levels
enum TextureQuality {
  /// Full resolution
  high,

  /// 75% resolution
  medium,

  /// 50% resolution
  low,

  /// 25% resolution (for thumbnails)
  thumbnail,
}

/// Texture compression configuration
class TextureCompressionConfig {
  /// Target format for compression
  final TextureFormat format;

  /// Quality level
  final TextureQuality quality;

  /// WebP quality (0-100, only for WebP format)
  final int webpQuality;

  /// ASTC block size (4x4, 5x5, 6x6, 8x8)
  final String astcBlockSize;

  /// Whether to generate mipmaps
  final bool generateMipmaps;

  /// Maximum texture dimension
  final int maxDimension;

  const TextureCompressionConfig({
    this.format = TextureFormat.webp,
    this.quality = TextureQuality.high,
    this.webpQuality = 85,
    this.astcBlockSize = '6x6',
    this.generateMipmaps = false,
    this.maxDimension = 4096,
  });

  /// High quality preset
  static const high = TextureCompressionConfig(
    format: TextureFormat.webp,
    quality: TextureQuality.high,
    webpQuality: 95,
    maxDimension: 4096,
  );

  /// Medium quality preset
  static const medium = TextureCompressionConfig(
    format: TextureFormat.webp,
    quality: TextureQuality.medium,
    webpQuality: 80,
    maxDimension: 2048,
  );

  /// Low quality preset (mobile-optimized)
  static const low = TextureCompressionConfig(
    format: TextureFormat.webp,
    quality: TextureQuality.low,
    webpQuality: 70,
    maxDimension: 1024,
  );

  /// ASTC preset for high-end mobile
  static const astcHigh = TextureCompressionConfig(
    format: TextureFormat.astc,
    quality: TextureQuality.high,
    astcBlockSize: '4x4',
    maxDimension: 4096,
  );

  /// ASTC preset for mid-range mobile
  static const astcMedium = TextureCompressionConfig(
    format: TextureFormat.astc,
    quality: TextureQuality.medium,
    astcBlockSize: '6x6',
    maxDimension: 2048,
  );

  Map<String, dynamic> toJson() => {
        'format': format.name,
        'quality': quality.name,
        'webpQuality': webpQuality,
        'astcBlockSize': astcBlockSize,
        'generateMipmaps': generateMipmaps,
        'maxDimension': maxDimension,
      };

  factory TextureCompressionConfig.fromJson(Map<String, dynamic> json) {
    return TextureCompressionConfig(
      format: TextureFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => TextureFormat.webp,
      ),
      quality: TextureQuality.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => TextureQuality.high,
      ),
      webpQuality: json['webpQuality'] as int? ?? 85,
      astcBlockSize: json['astcBlockSize'] as String? ?? '6x6',
      generateMipmaps: json['generateMipmaps'] as bool? ?? false,
      maxDimension: json['maxDimension'] as int? ?? 4096,
    );
  }
}

/// Compressed texture data
class CompressedTexture {
  /// Original resource ID
  final String id;

  /// Compression format used
  final TextureFormat format;

  /// Quality level
  final TextureQuality quality;

  /// Compressed data
  final Uint8List data;

  /// Original width
  final int originalWidth;

  /// Original height
  final int originalHeight;

  /// Compressed width
  final int compressedWidth;

  /// Compressed height
  final int compressedHeight;

  /// Original size in bytes
  final int originalSize;

  /// Compressed size in bytes
  int get compressedSize => data.length;

  /// Compression ratio
  double get compressionRatio =>
      originalSize > 0 ? compressedSize / originalSize : 1.0;

  /// Space saved percentage
  double get spaceSaved => 1.0 - compressionRatio;

  const CompressedTexture({
    required this.id,
    required this.format,
    required this.quality,
    required this.data,
    required this.originalWidth,
    required this.originalHeight,
    required this.compressedWidth,
    required this.compressedHeight,
    required this.originalSize,
  });
}

/// Texture compression result
class TextureCompressionResult {
  /// Whether compression succeeded
  final bool success;

  /// Compressed texture (null if failed)
  final CompressedTexture? texture;

  /// Error message (if failed)
  final String? error;

  /// Compression time in milliseconds
  final int compressionTimeMs;

  const TextureCompressionResult({
    required this.success,
    this.texture,
    this.error,
    this.compressionTimeMs = 0,
  });

  factory TextureCompressionResult.success(
    CompressedTexture texture, {
    int compressionTimeMs = 0,
  }) {
    return TextureCompressionResult(
      success: true,
      texture: texture,
      compressionTimeMs: compressionTimeMs,
    );
  }

  factory TextureCompressionResult.failure(String error) {
    return TextureCompressionResult(
      success: false,
      error: error,
    );
  }
}

/// Abstract texture compressor interface
abstract class TextureCompressor {
  /// Compress image data
  Future<TextureCompressionResult> compress(
    String id,
    Uint8List imageData,
    TextureCompressionConfig config,
  );

  /// Check if format is supported on current platform
  bool isFormatSupported(TextureFormat format);

  /// Get best format for current platform
  TextureFormat getBestFormat();
}

/// Default texture compressor implementation
class DefaultTextureCompressor implements TextureCompressor {
  @override
  Future<TextureCompressionResult> compress(
    String id,
    Uint8List imageData,
    TextureCompressionConfig config,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      // In a real implementation, this would use platform-specific
      // compression libraries (e.g., image package for WebP)

      // For now, simulate compression with size reduction
      final compressedData = await _simulateCompression(imageData, config);

      stopwatch.stop();

      return TextureCompressionResult.success(
        CompressedTexture(
          id: id,
          format: config.format,
          quality: config.quality,
          data: compressedData,
          originalWidth: 1920, // Would be extracted from image
          originalHeight: 1080,
          compressedWidth: _getCompressedDimension(1920, config),
          compressedHeight: _getCompressedDimension(1080, config),
          originalSize: imageData.length,
        ),
        compressionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return TextureCompressionResult.failure(e.toString());
    }
  }

  @override
  bool isFormatSupported(TextureFormat format) {
    switch (format) {
      case TextureFormat.original:
      case TextureFormat.webp:
        return true;
      case TextureFormat.astc:
        // ASTC is supported on most modern mobile GPUs
        return defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;
      case TextureFormat.etc2:
        return defaultTargetPlatform == TargetPlatform.android;
      case TextureFormat.pvrtc:
        return defaultTargetPlatform == TargetPlatform.iOS;
    }
  }

  @override
  TextureFormat getBestFormat() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return TextureFormat.astc;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return TextureFormat.astc;
    } else {
      return TextureFormat.webp;
    }
  }

  Future<Uint8List> _simulateCompression(
    Uint8List data,
    TextureCompressionConfig config,
  ) async {
    // Simulate compression ratio based on format and quality
    final ratio = _getCompressionRatio(config);
    final newSize = (data.length * ratio).round();

    // In real implementation, this would actually compress the image
    // For now, just return truncated data to simulate size reduction
    if (newSize < data.length) {
      return Uint8List.fromList(data.sublist(0, newSize));
    }
    return data;
  }

  double _getCompressionRatio(TextureCompressionConfig config) {
    final qualityFactor = switch (config.quality) {
      TextureQuality.high => 1.0,
      TextureQuality.medium => 0.75,
      TextureQuality.low => 0.5,
      TextureQuality.thumbnail => 0.25,
    };

    final formatFactor = switch (config.format) {
      TextureFormat.original => 1.0,
      TextureFormat.webp => 0.3 + (config.webpQuality / 100) * 0.4,
      TextureFormat.astc => 0.15,
      TextureFormat.etc2 => 0.2,
      TextureFormat.pvrtc => 0.2,
    };

    return qualityFactor * qualityFactor * formatFactor;
  }

  int _getCompressedDimension(int original, TextureCompressionConfig config) {
    final scaleFactor = switch (config.quality) {
      TextureQuality.high => 1.0,
      TextureQuality.medium => 0.75,
      TextureQuality.low => 0.5,
      TextureQuality.thumbnail => 0.25,
    };

    final scaled = (original * scaleFactor).round();
    return scaled.clamp(1, config.maxDimension);
  }
}


/// Texture cache with compression support
class CompressedTextureCache {
  final TextureCompressor _compressor;
  final TextureCompressionConfig _config;

  /// Cached compressed textures
  final Map<String, CompressedTexture> _cache = {};

  /// Compression statistics
  int _totalOriginalSize = 0;
  int _totalCompressedSize = 0;
  int _compressionCount = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  CompressedTextureCache({
    TextureCompressor? compressor,
    TextureCompressionConfig config = TextureCompressionConfig.medium,
  })  : _compressor = compressor ?? DefaultTextureCompressor(),
        _config = config;

  /// Get compression statistics
  Map<String, dynamic> get statistics => {
        'totalOriginalSize': _totalOriginalSize,
        'totalCompressedSize': _totalCompressedSize,
        'totalSaved': _totalOriginalSize - _totalCompressedSize,
        'averageCompressionRatio': _compressionCount > 0
            ? _totalCompressedSize / _totalOriginalSize
            : 1.0,
        'compressionCount': _compressionCount,
        'cacheHits': _cacheHits,
        'cacheMisses': _cacheMisses,
        'hitRate':
            (_cacheHits + _cacheMisses) > 0
                ? _cacheHits / (_cacheHits + _cacheMisses)
                : 0.0,
        'cachedTextures': _cache.length,
      };

  /// Get or compress a texture
  Future<CompressedTexture?> getOrCompress(
    String id,
    Uint8List imageData,
  ) async {
    // Check cache first
    if (_cache.containsKey(id)) {
      _cacheHits++;
      return _cache[id];
    }

    _cacheMisses++;

    // Compress the texture
    final result = await _compressor.compress(id, imageData, _config);

    if (result.success && result.texture != null) {
      _cache[id] = result.texture!;
      _totalOriginalSize += result.texture!.originalSize;
      _totalCompressedSize += result.texture!.compressedSize;
      _compressionCount++;
      return result.texture;
    }

    return null;
  }

  /// Get cached texture
  CompressedTexture? get(String id) {
    if (_cache.containsKey(id)) {
      _cacheHits++;
      return _cache[id];
    }
    _cacheMisses++;
    return null;
  }

  /// Check if texture is cached
  bool contains(String id) => _cache.containsKey(id);

  /// Remove texture from cache
  void remove(String id) {
    final texture = _cache.remove(id);
    if (texture != null) {
      _totalOriginalSize -= texture.originalSize;
      _totalCompressedSize -= texture.compressedSize;
    }
  }

  /// Clear all cached textures
  void clear() {
    _cache.clear();
    _totalOriginalSize = 0;
    _totalCompressedSize = 0;
  }

  /// Get total memory used by cache
  int get totalMemoryUsed => _totalCompressedSize;

  /// Get number of cached textures
  int get count => _cache.length;
}

/// Multi-quality texture manager
///
/// Manages textures at multiple quality levels for dynamic quality adjustment
class MultiQualityTextureManager {
  final TextureCompressor _compressor;

  /// Textures at different quality levels
  final Map<String, Map<TextureQuality, CompressedTexture>> _textures = {};

  /// Current quality level
  TextureQuality _currentQuality;

  MultiQualityTextureManager({
    TextureCompressor? compressor,
    TextureQuality initialQuality = TextureQuality.high,
  })  : _compressor = compressor ?? DefaultTextureCompressor(),
        _currentQuality = initialQuality;

  /// Get/set current quality level
  TextureQuality get currentQuality => _currentQuality;
  set currentQuality(TextureQuality value) {
    _currentQuality = value;
  }

  /// Generate all quality levels for a texture
  Future<void> generateAllQualities(String id, Uint8List imageData) async {
    _textures[id] = {};

    for (final quality in TextureQuality.values) {
      final config = TextureCompressionConfig(
        format: _compressor.getBestFormat(),
        quality: quality,
      );

      final result = await _compressor.compress(id, imageData, config);
      if (result.success && result.texture != null) {
        _textures[id]![quality] = result.texture!;
      }
    }
  }

  /// Get texture at current quality level
  CompressedTexture? getTexture(String id) {
    return _textures[id]?[_currentQuality];
  }

  /// Get texture at specific quality level
  CompressedTexture? getTextureAtQuality(String id, TextureQuality quality) {
    return _textures[id]?[quality];
  }

  /// Get best available texture (falls back to lower quality if needed)
  CompressedTexture? getBestAvailable(String id) {
    final qualities = _textures[id];
    if (qualities == null) return null;

    // Try current quality first
    if (qualities.containsKey(_currentQuality)) {
      return qualities[_currentQuality];
    }

    // Fall back to lower qualities
    for (final quality in TextureQuality.values.reversed) {
      if (qualities.containsKey(quality)) {
        return qualities[quality];
      }
    }

    return null;
  }

  /// Remove all quality levels for a texture
  void removeTexture(String id) {
    _textures.remove(id);
  }

  /// Clear all textures
  void clear() {
    _textures.clear();
  }

  /// Get memory usage at each quality level
  Map<TextureQuality, int> getMemoryByQuality() {
    final usage = <TextureQuality, int>{};

    for (final quality in TextureQuality.values) {
      int total = 0;
      for (final textures in _textures.values) {
        final texture = textures[quality];
        if (texture != null) {
          total += texture.compressedSize;
        }
      }
      usage[quality] = total;
    }

    return usage;
  }
}
