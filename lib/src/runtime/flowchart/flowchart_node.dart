/// Flowchart Node Model
///
/// Represents a node in the route flowchart visualization.
/// Requirements: 4.2

/// Flowchart node types
enum FlowchartNodeType {
  /// Story start point
  start,

  /// Scene/dialogue segment
  scene,

  /// Player choice point
  choice,

  /// Story ending
  ending,

  /// Jump/branch point
  jump,

  /// Condition branch
  condition,
}

/// A node in the flowchart visualization
class FlowchartNode {
  /// Unique node identifier (matches VNNode id)
  final String id;

  /// Display label for the node
  final String label;

  /// Node type
  final FlowchartNodeType type;

  /// IDs of child nodes (outgoing connections)
  final List<String> childIds;

  /// ID of the ending (if this is an ending node)
  final String? endingId;

  /// Chapter ID this node belongs to
  final String? chapterId;

  /// Optional description or hint text
  final String? description;

  /// Localized labels by language code
  final Map<String, String> localizedLabels;

  /// Display order for sorting
  final int order;

  const FlowchartNode({
    required this.id,
    required this.label,
    required this.type,
    this.childIds = const [],
    this.endingId,
    this.chapterId,
    this.description,
    this.localizedLabels = const {},
    this.order = 0,
  });

  /// Get localized label
  String getLocalizedLabel(String languageCode) {
    return localizedLabels[languageCode] ?? label;
  }

  /// Check if this is a branching node (has multiple children)
  bool get isBranching => childIds.length > 1;

  /// Check if this is a terminal node (no children)
  bool get isTerminal => childIds.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'childIds': childIds,
        if (endingId != null) 'endingId': endingId,
        if (chapterId != null) 'chapterId': chapterId,
        if (description != null) 'description': description,
        if (localizedLabels.isNotEmpty) 'localizedLabels': localizedLabels,
        'order': order,
      };

  factory FlowchartNode.fromJson(Map<String, dynamic> json) {
    return FlowchartNode(
      id: json['id'] as String,
      label: json['label'] as String,
      type: FlowchartNodeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FlowchartNodeType.scene,
      ),
      childIds: List<String>.from(json['childIds'] as List? ?? []),
      endingId: json['endingId'] as String?,
      chapterId: json['chapterId'] as String?,
      description: json['description'] as String?,
      localizedLabels:
          (json['localizedLabels'] as Map<String, dynamic>?)?.cast<String, String>() ??
              const {},
      order: json['order'] as int? ?? 0,
    );
  }

  FlowchartNode copyWith({
    String? id,
    String? label,
    FlowchartNodeType? type,
    List<String>? childIds,
    String? endingId,
    String? chapterId,
    String? description,
    Map<String, String>? localizedLabels,
    int? order,
  }) {
    return FlowchartNode(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      childIds: childIds ?? this.childIds,
      endingId: endingId ?? this.endingId,
      chapterId: chapterId ?? this.chapterId,
      description: description ?? this.description,
      localizedLabels: localizedLabels ?? this.localizedLabels,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowchartNode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Extension for FlowchartNodeType localization
extension FlowchartNodeTypeExtension on FlowchartNodeType {
  String getLocalizedName(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return _japaneseNames[this] ?? name;
      case 'zh':
        return _chineseNames[this] ?? name;
      default:
        return _englishNames[this] ?? name;
    }
  }

  static const _englishNames = {
    FlowchartNodeType.start: 'Start',
    FlowchartNodeType.scene: 'Scene',
    FlowchartNodeType.choice: 'Choice',
    FlowchartNodeType.ending: 'Ending',
    FlowchartNodeType.jump: 'Jump',
    FlowchartNodeType.condition: 'Condition',
  };

  static const _japaneseNames = {
    FlowchartNodeType.start: '開始',
    FlowchartNodeType.scene: 'シーン',
    FlowchartNodeType.choice: '選択',
    FlowchartNodeType.ending: 'エンディング',
    FlowchartNodeType.jump: 'ジャンプ',
    FlowchartNodeType.condition: '条件',
  };

  static const _chineseNames = {
    FlowchartNodeType.start: '开始',
    FlowchartNodeType.scene: '场景',
    FlowchartNodeType.choice: '选择',
    FlowchartNodeType.ending: '结局',
    FlowchartNodeType.jump: '跳转',
    FlowchartNodeType.condition: '条件',
  };
}
