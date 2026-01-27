import 'dart:math' as math;

/// A range of values with min and max bounds
class Range<T extends num> {
  final T min;
  final T max;
  
  const Range(this.min, this.max);
  
  /// Get a random value within this range
  double random(math.Random rng) {
    final minD = min.toDouble();
    final maxD = max.toDouble();
    return minD + rng.nextDouble() * (maxD - minD);
  }
  
  /// Lerp between min and max
  double lerp(double t) {
    final minD = min.toDouble();
    final maxD = max.toDouble();
    return minD + t * (maxD - minD);
  }
  
  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
  };
  
  static Range<double> fromJson(Map<String, dynamic> json) {
    return Range<double>(
      (json['min'] as num).toDouble(),
      (json['max'] as num).toDouble(),
    );
  }
  
  @override
  String toString() => 'Range($min, $max)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Range<T> && min == other.min && max == other.max;
  
  @override
  int get hashCode => Object.hash(min, max);
}
