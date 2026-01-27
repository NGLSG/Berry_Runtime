/// VNBS Performance Optimization Module
///
/// Provides performance optimization features for VN runtime:
/// - Lazy resource loading (Requirements: 24.1)
/// - Predictive preloading (Requirements: 24.2)
/// - Texture compression (Requirements: 24.3)
/// - Audio streaming (Requirements: 24.4)

library vnbs_performance;

export 'resource_loader.dart';
export 'chapter_resource_manager.dart';
export 'predictive_preloader.dart';
export 'texture_compression.dart';
export 'audio_streaming.dart';
