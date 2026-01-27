import 'dart:ui';

import 'story_graph.dart';

/// Canvas state for editor restoration
class CanvasState {
  /// Zoom level (1.0 = 100%)
  final double zoom;

  /// Pan offset X
  final double panX;

  /// Pan offset Y
  final double panY;

  /// Selected node IDs
  final List<String> selectedNodeIds;

  const CanvasState({
    this.zoom = 1.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.selectedNodeIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'zoom': zoom,
        'panX': panX,
        'panY': panY,
        'selectedNodeIds': selectedNodeIds,
      };

  factory CanvasState.fromJson(Map<String, dynamic> json) {
    return CanvasState(
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
      panX: (json['panX'] as num?)?.toDouble() ?? 0.0,
      panY: (json['panY'] as num?)?.toDouble() ?? 0.0,
      selectedNodeIds:
          (json['selectedNodeIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
    );
  }

  CanvasState copyWith({
    double? zoom,
    double? panX,
    double? panY,
    List<String>? selectedNodeIds,
  }) {
    return CanvasState(
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
    );
  }
}

/// A chapter in the visual novel project
class Chapter {
  /// Unique chapter identifier
  final String id;

  /// Chapter display title
  final String title;

  /// Optional chapter description
  final String? description;

  /// Chapter order in the project (0-based)
  final int order;

  /// Whether this chapter is a draft (excluded from release builds)
  final bool isDraft;

  /// The story graph for this chapter
  final StoryGraph graph;

  /// Editor canvas state for this chapter
  final CanvasState canvasState;

  /// Chapter template type (if created from template)
  final String? templateType;

  const Chapter({
    required this.id,
    required this.title,
    this.description,
    this.order = 0,
    this.isDraft = false,
    this.graph = const StoryGraph(),
    this.canvasState = const CanvasState(),
    this.templateType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        'order': order,
        'isDraft': isDraft,
        'graph': graph.toJson(),
        'canvasState': canvasState.toJson(),
        if (templateType != null) 'templateType': templateType,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      isDraft: json['isDraft'] as bool? ?? false,
      graph: json['graph'] != null
          ? StoryGraph.fromJson(json['graph'] as Map<String, dynamic>)
          : const StoryGraph(),
      canvasState: json['canvasState'] != null
          ? CanvasState.fromJson(json['canvasState'] as Map<String, dynamic>)
          : const CanvasState(),
      templateType: json['templateType'] as String?,
    );
  }

  Chapter copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    bool? isDraft,
    StoryGraph? graph,
    CanvasState? canvasState,
    String? templateType,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      isDraft: isDraft ?? this.isDraft,
      graph: graph ?? this.graph,
      canvasState: canvasState ?? this.canvasState,
      templateType: templateType ?? this.templateType,
    );
  }

  /// Create a new chapter with generated ID
  factory Chapter.create({
    required String title,
    String? description,
    int order = 0,
    String? templateType,
  }) {
    final id = 'chapter_${DateTime.now().millisecondsSinceEpoch}';
    return Chapter(
      id: id,
      title: title,
      description: description,
      order: order,
      templateType: templateType,
    );
  }
}
