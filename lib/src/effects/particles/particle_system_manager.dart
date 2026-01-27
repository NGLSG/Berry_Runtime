import 'dart:ui';
import 'package:flutter/material.dart';
import 'particle_emitter.dart';
import 'particle_emitter_config.dart';
import 'particle_presets.dart';

/// Manages multiple particle emitters
class ParticleSystemManager extends ChangeNotifier {
  final Map<String, ParticleEmitter> _emitters = {};
  
  /// Bounds for particle effects (typically screen size)
  Rect? bounds;

  /// All active emitter IDs
  Iterable<String> get activeEmitterIds => _emitters.keys;

  /// Number of active emitters
  int get emitterCount => _emitters.length;

  /// Total active particle count across all emitters
  int get totalParticleCount => 
      _emitters.values.fold(0, (sum, e) => sum + e.activeParticleCount);

  /// Check if an emitter exists
  bool hasEmitter(String id) => _emitters.containsKey(id);

  /// Get an emitter by ID
  ParticleEmitter? getEmitter(String id) => _emitters[id];

  /// Start a particle effect with configuration
  void startEffect(ParticleEmitterConfig config, {Rect? effectBounds}) {
    // Stop existing emitter with same ID if any
    if (_emitters.containsKey(config.id)) {
      _emitters[config.id]!.stopImmediate();
    }
    
    final emitter = ParticleEmitter(
      config,
      bounds: effectBounds ?? bounds,
    );
    _emitters[config.id] = emitter;
    emitter.start();
    notifyListeners();
  }

  /// Start a preset effect by name
  void startPreset(String presetName, {String? id, Rect? effectBounds}) {
    final config = ParticlePresets.getPreset(presetName, id: id);
    if (config != null) {
      startEffect(config, effectBounds: effectBounds);
    }
  }

  /// Stop a particle effect
  void stopEffect(String id, {bool immediate = false}) {
    final emitter = _emitters[id];
    if (emitter != null) {
      if (immediate) {
        emitter.stopImmediate();
        _emitters.remove(id);
      } else {
        emitter.stopGradual();
      }
      notifyListeners();
    }
  }

  /// Stop all effects
  void stopAllEffects({bool immediate = false}) {
    if (immediate) {
      for (final emitter in _emitters.values) {
        emitter.stopImmediate();
      }
      _emitters.clear();
    } else {
      for (final emitter in _emitters.values) {
        emitter.stopGradual();
      }
    }
    notifyListeners();
  }

  /// Set intensity for an effect
  void setIntensity(String id, double intensity) {
    _emitters[id]?.setIntensity(intensity);
  }

  /// Set intensity for all effects
  void setGlobalIntensity(double intensity) {
    for (final emitter in _emitters.values) {
      emitter.setIntensity(intensity);
    }
  }

  /// Update all emitters
  void update(double dt) {
    // Update all emitters
    for (final emitter in _emitters.values) {
      emitter.update(dt);
    }
    
    // Remove completed emitters
    _emitters.removeWhere((id, emitter) {
      if (emitter.isComplete) {
        emitter.dispose();
        return true;
      }
      return false;
    });
  }

  /// Render all particles to canvas
  void render(Canvas canvas, {Size? size}) {
    for (final emitter in _emitters.values) {
      emitter.render(canvas, size: size);
    }
  }

  /// Update bounds for all emitters
  void updateBounds(Rect newBounds) {
    bounds = newBounds;
    for (final emitter in _emitters.values) {
      emitter.bounds = newBounds;
    }
  }

  /// Dispose of all resources
  @override
  void dispose() {
    for (final emitter in _emitters.values) {
      emitter.dispose();
    }
    _emitters.clear();
    super.dispose();
  }
}
