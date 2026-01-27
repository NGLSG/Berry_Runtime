import '../models/vn_project.dart';
import '../models/vn_character.dart';
import '../models/vn_variable.dart';
import '../models/vn_theme.dart';
import 'vn_resource_manifest.dart';

/// Compiled chapter for runtime
class CompiledChapter {
  /// Chapter identifier
  final String id;

  /// Chapter title
  final String title;

  /// Optional description
  final String? description;

  /// ID of the start node
  final String startNodeId;

  /// Compiled nodes indexed by ID
  final Map<String, CompiledNode> nodes;

  const CompiledChapter({
    required this.id,
    required this.title,
    this.description,
    required this.startNodeId,
    required this.nodes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        'startNodeId': startNodeId,
        'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory CompiledChapter.fromJson(Map<String, dynamic> json) {
    return CompiledChapter(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startNodeId: json['startNodeId'] as String,
      nodes: (json['nodes'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, CompiledNode.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

/// Compiled node for runtime execution
class CompiledNode {
  /// Node type (start, scene, choice, jump, condition, variable, effect, audio, ending)
  final String type;

  /// Node-specific data
  final Map<String, dynamic> data;

  /// Next node ID (for linear flow)
  final String? next;

  const CompiledNode({
    required this.type,
    required this.data,
    this.next,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        ...data,
        if (next != null) 'next': next,
      };

  factory CompiledNode.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final next = json['next'] as String?;
    
    // Extract data (everything except type and next)
    final data = Map<String, dynamic>.from(json);
    data.remove('type');
    data.remove('next');

    return CompiledNode(
      type: type,
      data: data,
      next: next,
    );
  }
}

/// Compiled story bundle - the runtime format
class VNStoryBundle {
  /// Bundle version
  final String version;

  /// Project settings
  final VNProjectSettings settings;

  /// Compiled chapters
  final List<CompiledChapter> chapters;

  /// Character definitions
  final List<VNCharacter> characters;

  /// Variable definitions
  final List<VNVariable> variables;

  /// Resource manifest
  final VNResourceManifest resources;

  /// UI theme
  final VNTheme theme;

  const VNStoryBundle({
    required this.version,
    required this.settings,
    required this.chapters,
    required this.characters,
    required this.variables,
    required this.resources,
    required this.theme,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'settings': settings.toJson(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'characters': characters.map((c) => c.toJson()).toList(),
        'variables': variables.map((v) => v.toJson()).toList(),
        'resourceManifest': resources.toJson(),
        'theme': theme.toJson(),
      };

  factory VNStoryBundle.fromJson(Map<String, dynamic> json) {
    return VNStoryBundle(
      version: json['version'] as String,
      settings: VNProjectSettings.fromJson(json['settings'] as Map<String, dynamic>),
      chapters: (json['chapters'] as List<dynamic>)
          .map((c) => CompiledChapter.fromJson(c as Map<String, dynamic>))
          .toList(),
      characters: (json['characters'] as List<dynamic>)
          .map((c) => VNCharacter.fromJson(c as Map<String, dynamic>))
          .toList(),
      variables: (json['variables'] as List<dynamic>)
          .map((v) => VNVariable.fromJson(v as Map<String, dynamic>))
          .toList(),
      resources: VNResourceManifest.fromJson(json['resourceManifest'] as Map<String, dynamic>),
      theme: VNTheme.fromJson(json['theme'] as Map<String, dynamic>),
    );
  }

  /// Get a chapter by ID
  CompiledChapter? getChapter(String id) {
    try {
      return chapters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a character by ID
  VNCharacter? getCharacter(String id) {
    try {
      return characters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a variable definition by name
  VNVariable? getVariable(String name) {
    try {
      return variables.firstWhere((v) => v.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Get initial variable values
  Map<String, dynamic> getInitialVariables() {
    final values = <String, dynamic>{};
    for (final variable in variables) {
      values[variable.name] = variable.defaultValue;
    }
    return values;
  }
}
