import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'particle.dart';
import 'particle_pool.dart';
import 'particle_emitter_config.dart';
import 'particle_shape.dart';

/// Particle emitter that generates and manages particles
class ParticleEmitter {
  final ParticleEmitterConfig config;
  final ParticlePool _pool;
  final math.Random _random;
  
  /// Bounds for particle emission (screen area)
  Rect? bounds;
  
  /// Current emission rate multiplier (for intensity control)
  double _intensityMultiplier = 1.0;
  
  /// Whether the emitter is currently emitting
  bool _isEmitting = false;
  
  /// Whether the emitter is stopping (no new particles, waiting for existing to die)
  bool _isStopping = false;
  
  /// Accumulated time for emission timing
  double _emissionAccumulator = 0.0;
  
  /// Custom texture for custom shape particles
  ui.Image? _texture;

  ParticleEmitter(
    this.config, {
    this.bounds,
    math.Random? random,
  })  : _pool = ParticlePool(maxSize: config.maxParticles),
        _random = random ?? math.Random();

  /// Whether the emitter is currently active
  bool get isActive => _isEmitting || _pool.activeCount > 0;

  /// Whether the emitter has completed (stopped and all particles dead)
  bool get isComplete => _isStopping && _pool.activeCount == 0;

  /// Number of active particles
  int get activeParticleCount => _pool.activeCount;

  /// Current intensity multiplier
  double get intensity => _intensityMultiplier;

  /// All active particles
  Iterable<Particle> get particles => _pool.activeParticles;

  /// Start emitting particles
  void start() {
    _isEmitting = true;
    _isStopping = false;
    _emissionAccumulator = 0.0;
  }

  /// Stop emitting immediately (clears all particles)
  void stopImmediate() {
    _isEmitting = false;
    _isStopping = false;
    _pool.reset();
  }

  /// Stop emitting gradually (let existing particles die)
  void stopGradual() {
    _isEmitting = false;
    _isStopping = true;
  }

  /// Set emission intensity (0.0 to 2.0+)
  void setIntensity(double intensity) {
    _intensityMultiplier = intensity.clamp(0.0, 5.0);
  }

  /// Set custom texture for custom shape particles
  void setTexture(ui.Image texture) {
    _texture = texture;
  }

  /// Update the emitter and all particles
  void update(double dt) {
    // Update existing particles
    _pool.updateAll(dt, config.gravity, config.wind);
    
    // Emit new particles if active
    if (_isEmitting && !_isStopping) {
      _emitParticles(dt);
    }
  }

  void _emitParticles(double dt) {
    final effectiveRate = config.emissionRate * _intensityMultiplier;
    _emissionAccumulator += dt * effectiveRate;
    
    while (_emissionAccumulator >= 1.0 && _pool.availableCount > 0) {
      _emissionAccumulator -= 1.0;
      _spawnParticle();
    }
  }

  void _spawnParticle() {
    final particle = _pool.acquire();
    if (particle == null) return;
    
    // Calculate spawn position
    final spawnPos = _calculateSpawnPosition();
    
    // Calculate initial velocity based on emission angle and speed
    final angle = config.emissionAngle.random(_random) * math.pi / 180.0;
    final speed = config.initialSpeed.random(_random);
    final velocity = Offset(
      math.cos(angle) * speed,
      math.sin(angle) * speed,
    );
    
    // Calculate initial rotation
    final rotation = config.initialRotation.random(_random) * math.pi / 180.0;
    final rotationSpeed = config.rotationSpeed.random(_random) * math.pi / 180.0;
    
    // Initialize particle
    particle.initialize(
      position: spawnPos,
      velocity: velocity,
      size: config.initialSize.random(_random),
      rotation: rotation,
      rotationSpeed: rotationSpeed,
      lifetime: config.particleLifetime.inMilliseconds / 1000.0,
      startColor: config.startColor,
      endColor: config.endColor,
    );
  }

  Offset _calculateSpawnPosition() {
    if (config.spawnArea != null) {
      // Spawn within configured area
      return Offset(
        config.spawnArea!.left + _random.nextDouble() * config.spawnArea!.width,
        config.spawnArea!.top + _random.nextDouble() * config.spawnArea!.height,
      );
    } else if (bounds != null) {
      // Spawn along top edge of bounds (for falling effects)
      return Offset(
        bounds!.left + _random.nextDouble() * bounds!.width,
        bounds!.top - 10, // Slightly above visible area
      );
    } else {
      // Default spawn at origin
      return Offset.zero;
    }
  }

  /// Render all particles to canvas
  void render(Canvas canvas, {Size? size}) {
    for (final particle in _pool.activeParticles) {
      _renderParticle(canvas, particle);
    }
  }

  void _renderParticle(Canvas canvas, Particle particle) {
    final paint = Paint()
      ..color = particle.currentColor.withOpacity(
        particle.currentColor.opacity * config.fadeOutCurve.transform(1.0 - particle.progress),
      );

    canvas.save();
    canvas.translate(particle.position.dx, particle.position.dy);
    canvas.rotate(particle.rotation);

    switch (config.shape) {
      case ParticleShape.circle:
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
        break;
        
      case ParticleShape.square:
        final halfSize = particle.size / 2;
        canvas.drawRect(
          Rect.fromLTWH(-halfSize, -halfSize, particle.size, particle.size),
          paint,
        );
        break;
        
      case ParticleShape.line:
        paint.strokeWidth = particle.size / 3;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(0, -particle.size),
          Offset(0, particle.size),
          paint,
        );
        break;
        
      case ParticleShape.custom:
        if (_texture != null) {
          // Draw custom texture
          final textureWidth = _texture!.width.toDouble();
          final textureHeight = _texture!.height.toDouble();
          final srcRect = Rect.fromLTWH(0, 0, textureWidth, textureHeight);
          final dstRect = Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size,
          );
          canvas.drawImageRect(_texture!, srcRect, dstRect, paint);
        } else {
          // Fallback to circle if no texture
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
        }
        break;
    }

    canvas.restore();
  }

  /// Dispose of resources
  void dispose() {
    _pool.reset();
    _texture = null;
  }
}
