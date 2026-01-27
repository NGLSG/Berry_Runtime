import 'dart:ui';

/// A single particle in the particle system
class Particle {
  /// Current position
  Offset position;
  
  /// Current velocity (pixels/second)
  Offset velocity;
  
  /// Current size
  double size;
  
  /// Current rotation (radians)
  double rotation;
  
  /// Rotation speed (radians/second)
  double rotationSpeed;
  
  /// Time alive (seconds)
  double age;
  
  /// Maximum lifetime (seconds)
  double lifetime;
  
  /// Start color
  Color startColor;
  
  /// End color
  Color endColor;
  
  /// Whether this particle is active
  bool isActive;

  Particle({
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.size = 5.0,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
    this.age = 0.0,
    this.lifetime = 1.0,
    this.startColor = const Color(0xFFFFFFFF),
    this.endColor = const Color(0xFFFFFFFF),
    this.isActive = false,
  });

  /// Progress through lifetime (0.0 to 1.0)
  double get progress => lifetime > 0 ? (age / lifetime).clamp(0.0, 1.0) : 1.0;

  /// Whether this particle has expired
  bool get isExpired => age >= lifetime;

  /// Current interpolated color based on lifetime progress
  Color get currentColor => Color.lerp(startColor, endColor, progress) ?? startColor;

  /// Reset particle for reuse in pool
  void reset() {
    position = Offset.zero;
    velocity = Offset.zero;
    size = 5.0;
    rotation = 0.0;
    rotationSpeed = 0.0;
    age = 0.0;
    lifetime = 1.0;
    startColor = const Color(0xFFFFFFFF);
    endColor = const Color(0xFFFFFFFF);
    isActive = false;
  }

  /// Initialize particle with new values
  void initialize({
    required Offset position,
    required Offset velocity,
    required double size,
    required double rotation,
    required double rotationSpeed,
    required double lifetime,
    required Color startColor,
    required Color endColor,
  }) {
    this.position = position;
    this.velocity = velocity;
    this.size = size;
    this.rotation = rotation;
    this.rotationSpeed = rotationSpeed;
    this.lifetime = lifetime;
    this.startColor = startColor;
    this.endColor = endColor;
    age = 0.0;
    isActive = true;
  }

  /// Update particle state
  void update(double dt, Offset gravity, Offset wind) {
    if (!isActive) return;
    
    // Apply forces to velocity
    velocity = Offset(
      velocity.dx + (gravity.dx + wind.dx) * dt,
      velocity.dy + (gravity.dy + wind.dy) * dt,
    );
    
    // Update position
    position = Offset(
      position.dx + velocity.dx * dt,
      position.dy + velocity.dy * dt,
    );
    
    // Update rotation
    rotation += rotationSpeed * dt;
    
    // Update age
    age += dt;
    
    // Deactivate if expired
    if (isExpired) {
      isActive = false;
    }
  }
}
