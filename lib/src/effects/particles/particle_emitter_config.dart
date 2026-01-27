import 'dart:ui';
import 'package:flutter/material.dart';
import 'particle_shape.dart';
import 'range.dart';

/// Configuration for a particle emitter
class ParticleEmitterConfig {
  /// Unique identifier for this emitter
  final String id;
  
  /// Path to custom texture (for custom shape)
  final String? texturePath;
  
  /// Shape of particles
  final ParticleShape shape;
  
  /// Maximum number of particles alive at once
  final int maxParticles;
  
  /// Particles emitted per second
  final double emissionRate;
  
  /// How long each particle lives
  final Duration particleLifetime;
  
  /// Gravity force applied to particles (pixels/second²)
  final Offset gravity;
  
  /// Wind force applied to particles (pixels/second)
  final Offset wind;
  
  /// Initial speed range (pixels/second)
  final Range<double> initialSpeed;
  
  /// Initial size range (pixels)
  final Range<double> initialSize;
  
  /// Initial rotation range (degrees)
  final Range<double> initialRotation;
  
  /// Rotation speed range (degrees/second)
  final Range<double> rotationSpeed;
  
  /// Start color
  final Color startColor;
  
  /// End color (for color interpolation over lifetime)
  final Color endColor;
  
  /// Fade out curve for particle opacity
  final Curve fadeOutCurve;
  
  /// Emission angle range (degrees, 0 = right, 90 = down)
  final Range<double> emissionAngle;
  
  /// Spawn area bounds (relative to emitter position)
  final Rect? spawnArea;

  const ParticleEmitterConfig({
    required this.id,
    this.texturePath,
    this.shape = ParticleShape.circle,
    this.maxParticles = 100,
    this.emissionRate = 10.0,
    this.particleLifetime = const Duration(seconds: 3),
    this.gravity = const Offset(0, 50),
    this.wind = Offset.zero,
    this.initialSpeed = const Range(50, 100),
    this.initialSize = const Range(5, 10),
    this.initialRotation = const Range(0, 360),
    this.rotationSpeed = const Range(0, 0),
    this.startColor = Colors.white,
    this.endColor = Colors.white,
    this.fadeOutCurve = Curves.easeOut,
    this.emissionAngle = const Range(0, 360),
    this.spawnArea,
  });

  ParticleEmitterConfig copyWith({
    String? id,
    String? texturePath,
    ParticleShape? shape,
    int? maxParticles,
    double? emissionRate,
    Duration? particleLifetime,
    Offset? gravity,
    Offset? wind,
    Range<double>? initialSpeed,
    Range<double>? initialSize,
    Range<double>? initialRotation,
    Range<double>? rotationSpeed,
    Color? startColor,
    Color? endColor,
    Curve? fadeOutCurve,
    Range<double>? emissionAngle,
    Rect? spawnArea,
  }) {
    return ParticleEmitterConfig(
      id: id ?? this.id,
      texturePath: texturePath ?? this.texturePath,
      shape: shape ?? this.shape,
      maxParticles: maxParticles ?? this.maxParticles,
      emissionRate: emissionRate ?? this.emissionRate,
      particleLifetime: particleLifetime ?? this.particleLifetime,
      gravity: gravity ?? this.gravity,
      wind: wind ?? this.wind,
      initialSpeed: initialSpeed ?? this.initialSpeed,
      initialSize: initialSize ?? this.initialSize,
      initialRotation: initialRotation ?? this.initialRotation,
      rotationSpeed: rotationSpeed ?? this.rotationSpeed,
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
      fadeOutCurve: fadeOutCurve ?? this.fadeOutCurve,
      emissionAngle: emissionAngle ?? this.emissionAngle,
      spawnArea: spawnArea ?? this.spawnArea,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (texturePath != null) 'texturePath': texturePath,
    'shape': shape.name,
    'maxParticles': maxParticles,
    'emissionRate': emissionRate,
    'particleLifetimeMs': particleLifetime.inMilliseconds,
    'gravity': {'x': gravity.dx, 'y': gravity.dy},
    'wind': {'x': wind.dx, 'y': wind.dy},
    'initialSpeed': initialSpeed.toJson(),
    'initialSize': initialSize.toJson(),
    'initialRotation': initialRotation.toJson(),
    'rotationSpeed': rotationSpeed.toJson(),
    'startColor': startColor.value,
    'endColor': endColor.value,
    'emissionAngle': emissionAngle.toJson(),
    if (spawnArea != null) 'spawnArea': {
      'left': spawnArea!.left,
      'top': spawnArea!.top,
      'width': spawnArea!.width,
      'height': spawnArea!.height,
    },
  };

  factory ParticleEmitterConfig.fromJson(Map<String, dynamic> json) {
    final gravityJson = json['gravity'] as Map<String, dynamic>?;
    final windJson = json['wind'] as Map<String, dynamic>?;
    final spawnAreaJson = json['spawnArea'] as Map<String, dynamic>?;
    
    return ParticleEmitterConfig(
      id: json['id'] as String,
      texturePath: json['texturePath'] as String?,
      shape: ParticleShape.values.firstWhere(
        (e) => e.name == json['shape'],
        orElse: () => ParticleShape.circle,
      ),
      maxParticles: json['maxParticles'] as int? ?? 100,
      emissionRate: (json['emissionRate'] as num?)?.toDouble() ?? 10.0,
      particleLifetime: Duration(
        milliseconds: json['particleLifetimeMs'] as int? ?? 3000,
      ),
      gravity: gravityJson != null
          ? Offset(
              (gravityJson['x'] as num).toDouble(),
              (gravityJson['y'] as num).toDouble(),
            )
          : const Offset(0, 50),
      wind: windJson != null
          ? Offset(
              (windJson['x'] as num).toDouble(),
              (windJson['y'] as num).toDouble(),
            )
          : Offset.zero,
      initialSpeed: json['initialSpeed'] != null
          ? Range.fromJson(json['initialSpeed'] as Map<String, dynamic>)
          : const Range(50, 100),
      initialSize: json['initialSize'] != null
          ? Range.fromJson(json['initialSize'] as Map<String, dynamic>)
          : const Range(5, 10),
      initialRotation: json['initialRotation'] != null
          ? Range.fromJson(json['initialRotation'] as Map<String, dynamic>)
          : const Range(0, 360),
      rotationSpeed: json['rotationSpeed'] != null
          ? Range.fromJson(json['rotationSpeed'] as Map<String, dynamic>)
          : const Range(0, 0),
      startColor: Color(json['startColor'] as int? ?? 0xFFFFFFFF),
      endColor: Color(json['endColor'] as int? ?? 0xFFFFFFFF),
      emissionAngle: json['emissionAngle'] != null
          ? Range.fromJson(json['emissionAngle'] as Map<String, dynamic>)
          : const Range(0, 360),
      spawnArea: spawnAreaJson != null
          ? Rect.fromLTWH(
              (spawnAreaJson['left'] as num).toDouble(),
              (spawnAreaJson['top'] as num).toDouble(),
              (spawnAreaJson['width'] as num).toDouble(),
              (spawnAreaJson['height'] as num).toDouble(),
            )
          : null,
    );
  }
}
