/// VN Runtime Rendering Module
/// 
/// This module provides the complete rendering system for visual novel runtime.
/// Includes background, character, effects, and audio management.
library vn_rendering;

// Background rendering
// Hide BackgroundTransition to avoid conflict with vn_node.dart
export 'background_layer.dart' hide BackgroundTransition;

// Character rendering
export 'character_layer.dart';

// Screen and text effects (hide duplicates defined in effects/text/)
export 'effects_layer.dart' hide EffectText, TextEffectConfig;

// Audio management
export 'audio_manager.dart';

// Unified story player
export 'story_player.dart';
