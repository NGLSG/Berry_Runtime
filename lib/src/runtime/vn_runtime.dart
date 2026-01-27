/// VN Runtime Module
/// 
/// This module provides the runtime engine for playing visual novels.
/// It can be used both for preview within the editor (via WebView)
/// and for standalone playback.
library vn_runtime;

// Core engine
export 'vn_engine.dart';
export 'vn_engine_state.dart';
export 'node_executor.dart';
export 'variable_manager.dart';

// Debug API
export 'debug/debug_api.dart';
export 'debug/debug_event.dart';

// UI Framework
export 'ui/vn_runtime_ui.dart';

// Rendering System
export 'rendering/vn_rendering.dart';

// Voice-Text Synchronization
export 'voice/voice.dart';

// Save System
export 'save/save.dart';

// Progress System
export 'progress/progress.dart';

// Achievements System
export 'achievements/achievements.dart';

// Endings System
export 'endings/endings.dart';

// Scene Replay System
export 'replay/replay.dart';

// Statistics System
export 'statistics/statistics.dart';

// Flowchart System
export 'flowchart/flowchart.dart';

// Protection System
export 'protection/protection.dart';

// New Game+ and Chapter Select System
export 'newgameplus/newgameplus.dart';
