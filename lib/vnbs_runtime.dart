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

// Core runtime
export 'src/runtime/vn_engine.dart';
export 'src/runtime/vn_engine_state.dart';
export 'src/runtime/node_executor.dart';
export 'src/runtime/variable_manager.dart';
export 'src/runtime/vn_runtime.dart';
export 'src/runtime/chapter_jump_controller.dart';

// Models
export 'src/models/vn_character.dart';
export 'src/models/vn_theme.dart';
export 'src/models/vn_project.dart';
export 'src/models/vn_variable.dart';
export 'src/models/vn_node.dart';
export 'src/models/vn_resource.dart';
export 'src/models/chapter.dart';
export 'src/models/story_graph.dart';
export 'src/models/story_graph_validator.dart';

// Compiler/Bundle
export 'src/compiler/vn_story_bundle.dart';
export 'src/compiler/vn_resource_manifest.dart';

// Rendering
export 'src/runtime/rendering/vn_rendering.dart';

// UI Components
export 'src/runtime/ui/vn_runtime_ui.dart';

// Effects
export 'src/runtime/effects/effects.dart';

// Save System
export 'src/runtime/save/save.dart';

// Scripting
export 'src/runtime/scripting/scripting.dart';

// Debug
export 'src/runtime/debug/debug_api.dart';
export 'src/runtime/debug/debug_event.dart';

// Accessibility
export 'src/runtime/accessibility/accessibility.dart';

// Achievements
export 'src/runtime/achievements/achievements.dart';

// Affection System
export 'src/runtime/affection/affection.dart';

// Endings
export 'src/runtime/endings/endings.dart';

// Flowchart
export 'src/runtime/flowchart/flowchart.dart';

// Journal
export 'src/runtime/journal/journal.dart';

// Localization
export 'src/runtime/localization/localization_manager.dart';
export 'src/runtime/localization/vn_ui_strings.dart';

// Minigame
export 'src/runtime/minigame/minigame.dart';

// New Game Plus
export 'src/runtime/newgameplus/newgameplus.dart';

// Performance
export 'src/runtime/performance/performance.dart';

// Progress
export 'src/runtime/progress/progress.dart';

// Protection
export 'src/runtime/protection/protection.dart';

// Replay
export 'src/runtime/replay/replay.dart';

// Statistics
export 'src/runtime/statistics/statistics.dart';

// Voice
export 'src/runtime/voice/voice.dart';
