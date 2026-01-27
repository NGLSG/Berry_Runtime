/// VNBS Runtime - Visual Novel Runtime Engine
///
/// Core runtime library for visual novel games created with Choccy IDE.
///
/// This library provides:
/// - Story engine for executing visual novel scripts
/// - Character rendering with expressions and animations
/// - Background and scene management
/// - Audio management (BGM, SFX, Voice)
/// - UI components (dialogue box, choice panel, menus)
/// - Save/Load system
/// - Effects (screen effects, particles, meta effects)
library vnbs_runtime;

// Core engine
export 'src/engine/vn_engine.dart';
export 'src/engine/vn_engine_state.dart';
export 'src/engine/node_executor.dart';
export 'src/engine/variable_manager.dart';

// Models
export 'src/models/vn_character.dart';
export 'src/models/vn_theme.dart';
export 'src/models/vn_project.dart';
export 'src/models/vn_variable.dart';
export 'src/models/vn_node.dart';
export 'src/models/vn_resource.dart';
export 'src/models/chapter.dart';
export 'src/models/story_graph.dart';

// Compiler/Bundle
export 'src/compiler/vn_story_bundle.dart';
export 'src/compiler/vn_resource_manifest.dart';

// Rendering
export 'src/rendering/character_layer.dart';
export 'src/rendering/background_layer.dart';
export 'src/rendering/effects_layer.dart';
export 'src/rendering/audio_manager.dart';
export 'src/rendering/story_player.dart';

// UI Components
export 'src/ui/main_menu.dart';
export 'src/ui/enhanced_main_menu.dart';
export 'src/ui/quick_menu.dart';
export 'src/ui/adv_textbox.dart';
export 'src/ui/choice_panel.dart';
export 'src/ui/save_load_screen.dart';
export 'src/ui/settings_screen.dart';
export 'src/ui/backlog_screen.dart';
export 'src/ui/gallery_screen.dart';

// Effects
export 'src/effects/text/text_effect_parser.dart';
export 'src/effects/text/text_effect_widgets.dart';
export 'src/effects/meta/meta_effects.dart';
export 'src/effects/meta/story_meta_effects.dart';
export 'src/effects/particles/particle_layer.dart';
export 'src/effects/particles/particle_presets.dart';
export 'src/effects/particles/particles.dart';
export 'src/effects/particles/particle_shape.dart';
export 'src/effects/particles/range.dart';
export 'src/effects/particles/particle_emitter_config.dart';
export 'src/effects/particles/particle.dart';
export 'src/effects/particles/particle_pool.dart';
export 'src/effects/particles/particle_emitter.dart';
export 'src/effects/particles/particle_system_manager.dart';
