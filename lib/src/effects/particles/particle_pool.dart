import 'dart:ui';
import 'particle.dart';

/// Object pool for particles to reduce GC pressure
class ParticlePool {
  final List<Particle> _pool;
  final int _maxSize;
  int _activeCount = 0;

  ParticlePool({int maxSize = 500})
      : _maxSize = maxSize,
        _pool = List.generate(maxSize, (_) => Particle());

  /// Number of active particles
  int get activeCount => _activeCount;

  /// Number of available particles in pool
  int get availableCount => _maxSize - _activeCount;

  /// Maximum pool size
  int get maxSize => _maxSize;

  /// Get all active particles
  Iterable<Particle> get activeParticles => 
      _pool.where((p) => p.isActive);

  /// Acquire a particle from the pool
  /// Returns null if pool is exhausted
  Particle? acquire() {
    for (final particle in _pool) {
      if (!particle.isActive) {
        _activeCount++;
        return particle;
      }
    }
    return null; // Pool exhausted
  }

  /// Release a particle back to the pool
  void release(Particle particle) {
    if (particle.isActive) {
      particle.reset();
      _activeCount--;
    }
  }

  /// Release all expired particles
  void releaseExpired() {
    for (final particle in _pool) {
      if (particle.isActive && particle.isExpired) {
        particle.reset();
        _activeCount--;
      }
    }
  }

  /// Reset all particles
  void reset() {
    for (final particle in _pool) {
      particle.reset();
    }
    _activeCount = 0;
  }

  /// Update all active particles
  void updateAll(double dt, Offset gravity, Offset wind) {
    for (final particle in _pool) {
      if (particle.isActive) {
        particle.update(dt, gravity, wind);
        if (!particle.isActive) {
          _activeCount--;
        }
      }
    }
  }
}
