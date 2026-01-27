import 'dart:ui';
import 'package:flutter/material.dart';
import 'particle_emitter_config.dart';
import 'particle_shape.dart';
import 'range.dart';

/// Preset particle effect configurations
class ParticlePresets {
  ParticlePresets._();

  /// Rain effect - vertical lines falling down
  static ParticleEmitterConfig rain({String id = 'rain'}) => ParticleEmitterConfig(
    id: id,
    shape: ParticleShape.line,
    maxParticles: 200,
    emissionRate: 50,
    particleLifetime: const Duration(seconds: 2),
    gravity: const Offset(0, 300),
    wind: const Offset(-20, 0),
    initialSpeed: const Range(200, 300),
    initialSize: const Range(2, 4),
    initialRotation: const Range(80, 100), // Nearly vertical
    rotationSpeed: const Range(0, 0),
    startColor: const Color(0x80FFFFFF),
    endColor: const Color(0xAAFFFFFF),
    emissionAngle: const Range(85, 95), // Downward
  );

  /// Snow effect - gentle falling circles
  static ParticleEmitterConfig snow({String id = 'snow'}) => ParticleEmitterConfig(
    id: id,
    shape: ParticleShape.circle,
    maxParticles: 100,
    emissionRate: 20,
    particleLifetime: const Duration(seconds: 5),
    gravity: const Offset(0, 30),
    wind: const Offset(10, 0),
    initialSpeed: const Range(20, 50),
    initialSize: const Range(3, 8),
    initialRotation: const Range(0, 360),
    rotationSpeed: const Range(-30, 30),
    startColor: Colors.white,
    endColor: const Color(0xEEFFFFFF),
    emissionAngle: const Range(70, 110), // Mostly downward with some spread
  );

  /// Sakura petals - floating flower petals
  static ParticleEmitterConfig sakura({String id = 'sakura'}) => ParticleEmitterConfig(
    id: id,
    texturePath: 'assets/particles/sakura.png',
    shape: ParticleShape.custom,
    maxParticles: 50,
    emissionRate: 10,
    particleLifetime: const Duration(seconds: 6),
    gravity: const Offset(0, 20),
    wind: const Offset(30, 0),
    initialSpeed: const Range(30, 60),
    initialSize: const Range(15, 25),
    initialRotation: const Range(0, 360),
    rotationSpeed: const Range(-60, 60),
    startColor: const Color(0xFFFFB7C5), // Pink
    endColor: const Color(0xAAFFB7C5),
    emissionAngle: const Range(45, 135),
  );

  /// Sparkles effect - twinkling stars
  static ParticleEmitterConfig sparkles({String id = 'sparkles'}) => ParticleEmitterConfig(
    id: id,
    shape: ParticleShape.circle,
    maxParticles: 80,
    emissionRate: 15,
    particleLifetime: const Duration(milliseconds: 1500),
    gravity: const Offset(0, -10), // Float upward slightly
    wind: Offset.zero,
    initialSpeed: const Range(10, 30),
    initialSize: const Range(2, 6),
    initialRotation: const Range(0, 360),
    rotationSpeed: const Range(0, 0),
    startColor: const Color(0xFFFFFFAA), // Yellow-white
    endColor: const Color(0x00FFFFAA),
    emissionAngle: const Range(0, 360), // All directions
  );

  /// Dust particles - floating dust motes
  static ParticleEmitterConfig dust({String id = 'dust'}) => ParticleEmitterConfig(
    id: id,
    shape: ParticleShape.circle,
    maxParticles: 60,
    emissionRate: 8,
    particleLifetime: const Duration(seconds: 8),
    gravity: const Offset(0, 5),
    wind: const Offset(5, 0),
    initialSpeed: const Range(5, 15),
    initialSize: const Range(1, 3),
    initialRotation: const Range(0, 360),
    rotationSpeed: const Range(0, 0),
    startColor: const Color(0x40FFFFFF),
    endColor: const Color(0x20FFFFFF),
    emissionAngle: const Range(0, 360),
  );

  /// Fireflies effect - glowing floating lights
  static ParticleEmitterConfig fireflies({String id = 'fireflies'}) => ParticleEmitterConfig(
    id: id,
    shape: ParticleShape.circle,
    maxParticles: 30,
    emissionRate: 5,
    particleLifetime: const Duration(seconds: 4),
    gravity: const Offset(0, -5), // Float upward
    wind: const Offset(3, 0),
    initialSpeed: const Range(10, 25),
    initialSize: const Range(4, 8),
    initialRotation: const Range(0, 360),
    rotationSpeed: const Range(0, 0),
    startColor: const Color(0xFFAAFF00), // Yellow-green glow
    endColor: const Color(0x00AAFF00),
    emissionAngle: const Range(0, 360),
  );

  /// Leaves falling effect
  static ParticleEmitterConfig leaves({String id = 'leaves'}) => ParticleEmitterConfig(
    id: id,
    shape: ParticleShape.square, // Or custom with leaf texture
    maxParticles: 40,
    emissionRate: 8,
    particleLifetime: const Duration(seconds: 5),
    gravity: const Offset(0, 40),
    wind: const Offset(20, 0),
    initialSpeed: const Range(20, 40),
    initialSize: const Range(10, 18),
    initialRotation: const Range(0, 360),
    rotationSpeed: const Range(-90, 90),
    startColor: const Color(0xFFD4A574), // Brown/orange
    endColor: const Color(0xAAD4A574),
    emissionAngle: const Range(60, 120),
  );

  /// Bubbles effect - rising bubbles
  static ParticleEmitterConfig bubbles({String id = 'bubbles'}) => ParticleEmitterConfig(
    id: id,
    shape: ParticleShape.circle,
    maxParticles: 50,
    emissionRate: 12,
    particleLifetime: const Duration(seconds: 4),
    gravity: const Offset(0, -50), // Float upward
    wind: const Offset(5, 0),
    initialSpeed: const Range(30, 60),
    initialSize: const Range(8, 20),
    initialRotation: const Range(0, 360),
    rotationSpeed: const Range(0, 0),
    startColor: const Color(0x60AADDFF),
    endColor: const Color(0x20AADDFF),
    emissionAngle: const Range(250, 290), // Upward
  );

  /// Smoke effect - rising smoke
  static ParticleEmitterConfig smoke({String id = 'smoke'}) => ParticleEmitterConfig(
    id: id,
    shape: ParticleShape.circle,
    maxParticles: 80,
    emissionRate: 20,
    particleLifetime: const Duration(seconds: 3),
    gravity: const Offset(0, -30), // Rise upward
    wind: const Offset(10, 0),
    initialSpeed: const Range(20, 40),
    initialSize: const Range(15, 30),
    initialRotation: const Range(0, 360),
    rotationSpeed: const Range(-20, 20),
    startColor: const Color(0x80808080), // Gray
    endColor: const Color(0x00808080),
    emissionAngle: const Range(250, 290), // Upward
  );

  /// Get preset by name
  static ParticleEmitterConfig? getPreset(String name, {String? id}) {
    switch (name.toLowerCase()) {
      case 'rain':
        return rain(id: id ?? 'rain');
      case 'snow':
        return snow(id: id ?? 'snow');
      case 'sakura':
        return sakura(id: id ?? 'sakura');
      case 'sparkles':
        return sparkles(id: id ?? 'sparkles');
      case 'dust':
        return dust(id: id ?? 'dust');
      case 'fireflies':
        return fireflies(id: id ?? 'fireflies');
      case 'leaves':
        return leaves(id: id ?? 'leaves');
      case 'bubbles':
        return bubbles(id: id ?? 'bubbles');
      case 'smoke':
        return smoke(id: id ?? 'smoke');
      default:
        return null;
    }
  }

  /// List of all available preset names
  static const List<String> presetNames = [
    'rain',
    'snow',
    'sakura',
    'sparkles',
    'dust',
    'fireflies',
    'leaves',
    'bubbles',
    'smoke',
  ];
}
