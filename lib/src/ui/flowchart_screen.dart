/// Flowchart Screen Widget
///
/// Displays the route flowchart visualization showing story branches
/// and player progress through the narrative.
/// Requirements: 4.1, 4.4, 4.5, 4.6

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../flowchart/flowchart.dart';

/// Configuration for the flowchart screen
class FlowchartScreenConfig {
  /// Background color
  final Color backgroundColor;

  /// Panel background color
  final Color panelBackgroundColor;

  /// Text color
  final Color textColor;

  /// Secondary text color
  final Color secondaryTextColor;

  /// Accent color
  final Color accentColor;

  /// Visited node color
  final Color visitedNodeColor;

  /// Unvisited node color
  final Color unvisitedNodeColor;

  /// Visited edge color
  final Color visitedEdgeColor;

  /// Unvisited edge color
  final Color unvisitedEdgeColor;

  /// Start node color
  final Color startNodeColor;

  /// Choice node color
  final Color choiceNodeColor;

  /// Ending node color
  final Color endingNodeColor;

  /// Node size
  final Size nodeSize;

  /// Horizontal spacing between nodes
  final double horizontalSpacing;

  /// Vertical spacing between levels
  final double verticalSpacing;

  /// Edge line width
  final double edgeWidth;

  /// Title font size
  final double titleFontSize;

  /// Whether to show node labels
  final bool showNodeLabels;

  /// Whether to enable node click to jump
  final bool enableJumpToNode;

  const FlowchartScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.accentColor = const Color(0xFF6C63FF),
    this.visitedNodeColor = const Color(0xFF4CAF50),
    this.unvisitedNodeColor = const Color(0xFF424242),
    this.visitedEdgeColor = const Color(0xFF4CAF50),
    this.unvisitedEdgeColor = const Color(0xFF616161),
    this.startNodeColor = const Color(0xFF2196F3),
    this.choiceNodeColor = const Color(0xFFFF9800),
    this.endingNodeColor = const Color(0xFFE91E63),
    this.nodeSize = const Size(120, 60),
    this.horizontalSpacing = 40.0,
    this.verticalSpacing = 80.0,
    this.edgeWidth = 2.0,
    this.titleFontSize = 28.0,
    this.showNodeLabels = true,
    this.enableJumpToNode = true,
  });

  /// Get color for node type
  Color getNodeTypeColor(FlowchartNodeType type) {
    switch (type) {
      case FlowchartNodeType.start:
        return startNodeColor;
      case FlowchartNodeType.choice:
        return choiceNodeColor;
      case FlowchartNodeType.ending:
        return endingNodeColor;
      default:
        return accentColor;
    }
  }
}

/// Flowchart screen widget
class FlowchartScreen extends StatefulWidget {
  /// Flowchart data to display
  final FlowchartData flowchartData;

  /// State manager for tracking visited nodes/edges
  final FlowchartStateManager stateManager;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Callback when a node is clicked (for jump functionality)
  final void Function(FlowchartNode)? onNodeTap;

  /// Configuration
  final FlowchartScreenConfig config;

  /// Language code for localization
  final String languageCode;

  const FlowchartScreen({
    super.key,
    required this.flowchartData,
    required this.stateManager,
    this.onBack,
    this.onNodeTap,
    this.config = const FlowchartScreenConfig(),
    this.languageCode = 'en',
  });

  @override
  State<FlowchartScreen> createState() => _FlowchartScreenState();
}

class _FlowchartScreenState extends State<FlowchartScreen> {
  final TransformationController _transformController = TransformationController();
  FlowchartNode? _selectedNode;
  bool _showOnlyVisited = false;

  // Layout data
  late Map<String, Offset> _nodePositions;
  late Size _graphSize;

  @override
  void initState() {
    super.initState();
    _calculateLayout();
  }

  @override
  void didUpdateWidget(FlowchartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flowchartData != widget.flowchartData) {
      _calculateLayout();
    }
  }

  void _calculateLayout() {
    _nodePositions = {};
    final levelNodes = <int, List<FlowchartNode>>{};

    // BFS to assign levels
    final visited = <String>{};
    final queue = <_NodeLevel>[];

    if (widget.flowchartData.rootId.isNotEmpty) {
      queue.add(_NodeLevel(widget.flowchartData.rootId, 0));
    }

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current.nodeId)) continue;
      visited.add(current.nodeId);

      final node = widget.flowchartData.getNode(current.nodeId);
      if (node == null) continue;

      levelNodes.putIfAbsent(current.level, () => []).add(node);

      for (final childId in node.childIds) {
        if (!visited.contains(childId)) {
          queue.add(_NodeLevel(childId, current.level + 1));
        }
      }
    }

    // Calculate positions
    double maxWidth = 0;
    double maxHeight = 0;

    for (final entry in levelNodes.entries) {
      final level = entry.key;
      final nodes = entry.value;
      final y = level * (widget.config.nodeSize.height + widget.config.verticalSpacing);

      final totalWidth = nodes.length * widget.config.nodeSize.width +
          (nodes.length - 1) * widget.config.horizontalSpacing;
      final startX = -totalWidth / 2;

      for (int i = 0; i < nodes.length; i++) {
        final x = startX +
            i * (widget.config.nodeSize.width + widget.config.horizontalSpacing);
        _nodePositions[nodes[i].id] = Offset(x, y);
        maxWidth = math.max(maxWidth, x.abs() + widget.config.nodeSize.width);
      }
      maxHeight = math.max(maxHeight, y + widget.config.nodeSize.height);
    }

    _graphSize = Size(maxWidth * 2 + 100, maxHeight + 100);
  }

  double get _nodeCompletionPercentage =>
      widget.stateManager.getNodeCompletionPercentage(widget.flowchartData);

  double get _edgeCompletionPercentage =>
      widget.stateManager.getEdgeCompletionPercentage(widget.flowchartData);

  double get _endingCompletionPercentage =>
      widget.stateManager.getEndingCompletionPercentage(widget.flowchartData);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressSummary(),
            _buildFilterToggle(),
            Expanded(
              child: _buildFlowchartView(),
            ),
            if (_selectedNode != null) _buildNodeDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: widget.config.textColor),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          Text(
            _getLocalizedTitle(),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: widget.config.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.center_focus_strong, color: widget.config.textColor),
            onPressed: _resetView,
            tooltip: 'Reset View',
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle() {
    switch (widget.languageCode) {
      case 'ja':
        return 'ルートフローチャート';
      case 'zh':
        return '路线流程图';
      default:
        return 'Route Flowchart';
    }
  }

  Widget _buildProgressSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildProgressRow(
            _getLocalizedNodesExplored(),
            _nodeCompletionPercentage,
            widget.config.visitedNodeColor,
          ),
          const SizedBox(height: 8),
          _buildProgressRow(
            _getLocalizedPathsDiscovered(),
            _edgeCompletionPercentage,
            widget.config.visitedEdgeColor,
          ),
          const SizedBox(height: 8),
          _buildProgressRow(
            _getLocalizedEndingsReached(),
            _endingCompletionPercentage,
            widget.config.endingNodeColor,
          ),
        ],
      ),
    );
  }

  String _getLocalizedNodesExplored() {
    switch (widget.languageCode) {
      case 'ja':
        return 'シーン探索';
      case 'zh':
        return '场景探索';
      default:
        return 'Scenes Explored';
    }
  }

  String _getLocalizedPathsDiscovered() {
    switch (widget.languageCode) {
      case 'ja':
        return 'ルート発見';
      case 'zh':
        return '路线发现';
      default:
        return 'Paths Discovered';
    }
  }

  String _getLocalizedEndingsReached() {
    switch (widget.languageCode) {
      case 'ja':
        return 'エンディング到達';
      case 'zh':
        return '结局达成';
      default:
        return 'Endings Reached';
    }
  }

  Widget _buildProgressRow(String label, double percentage, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: widget.config.unvisitedNodeColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            _getLocalizedShowOnlyVisited(),
            style: TextStyle(
              color: widget.config.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Switch(
            value: _showOnlyVisited,
            onChanged: (value) => setState(() => _showOnlyVisited = value),
            activeColor: widget.config.accentColor,
          ),
        ],
      ),
    );
  }

  String _getLocalizedShowOnlyVisited() {
    switch (widget.languageCode) {
      case 'ja':
        return '訪問済みのみ表示';
      case 'zh':
        return '仅显示已访问';
      default:
        return 'Show only visited';
    }
  }

  Widget _buildFlowchartView() {
    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.1,
      maxScale: 3.0,
      child: SizedBox(
        width: _graphSize.width,
        height: _graphSize.height,
        child: CustomPaint(
          painter: _FlowchartPainter(
            flowchartData: widget.flowchartData,
            stateManager: widget.stateManager,
            nodePositions: _nodePositions,
            config: widget.config,
            showOnlyVisited: _showOnlyVisited,
            selectedNodeId: _selectedNode?.id,
          ),
          child: Stack(
            children: widget.flowchartData.nodes.map((node) {
              final position = _nodePositions[node.id];
              if (position == null) return const SizedBox.shrink();

              final isVisited = widget.stateManager.isNodeVisited(node.id);
              if (_showOnlyVisited && !isVisited) {
                return const SizedBox.shrink();
              }

              return Positioned(
                left: position.dx + _graphSize.width / 2,
                top: position.dy + 50,
                child: _FlowchartNodeWidget(
                  node: node,
                  isVisited: isVisited,
                  isSelected: _selectedNode?.id == node.id,
                  config: widget.config,
                  languageCode: widget.languageCode,
                  onTap: () => _onNodeTap(node),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _onNodeTap(FlowchartNode node) {
    setState(() {
      _selectedNode = _selectedNode?.id == node.id ? null : node;
    });
  }

  void _resetView() {
    _transformController.value = Matrix4.identity();
  }

  Widget _buildNodeDetails() {
    if (_selectedNode == null) return const SizedBox.shrink();

    final node = _selectedNode!;
    final isVisited = widget.stateManager.isNodeVisited(node.id);
    final visitCount = widget.stateManager.getNodeVisitCount(node.id);
    final firstVisit = widget.stateManager.getNodeFirstVisitTime(node.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.config.getNodeTypeColor(node.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  node.type.getLocalizedName(widget.languageCode),
                  style: TextStyle(
                    color: widget.config.getNodeTypeColor(node.type),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: widget.config.textColor),
                onPressed: () => setState(() => _selectedNode = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            node.getLocalizedLabel(widget.languageCode),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (node.description != null) ...[
            const SizedBox(height: 4),
            Text(
              node.description!,
              style: TextStyle(
                color: widget.config.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDetailChip(
                icon: isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
                label: isVisited ? _getLocalizedVisited() : _getLocalizedNotVisited(),
                color: isVisited
                    ? widget.config.visitedNodeColor
                    : widget.config.unvisitedNodeColor,
              ),
              const SizedBox(width: 8),
              if (isVisited)
                _buildDetailChip(
                  icon: Icons.repeat,
                  label: '$visitCount ${_getLocalizedVisits()}',
                  color: widget.config.accentColor,
                ),
            ],
          ),
          if (firstVisit != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_getLocalizedFirstVisit()}: ${_formatDate(firstVisit)}',
              style: TextStyle(
                color: widget.config.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
          if (widget.config.enableJumpToNode &&
              isVisited &&
              widget.onNodeTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onNodeTap!(node),
                icon: const Icon(Icons.play_arrow),
                label: Text(_getLocalizedJumpToNode()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.config.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getLocalizedVisited() {
    switch (widget.languageCode) {
      case 'ja':
        return '訪問済み';
      case 'zh':
        return '已访问';
      default:
        return 'Visited';
    }
  }

  String _getLocalizedNotVisited() {
    switch (widget.languageCode) {
      case 'ja':
        return '未訪問';
      case 'zh':
        return '未访问';
      default:
        return 'Not Visited';
    }
  }

  String _getLocalizedVisits() {
    switch (widget.languageCode) {
      case 'ja':
        return '回';
      case 'zh':
        return '次';
      default:
        return 'visits';
    }
  }

  String _getLocalizedFirstVisit() {
    switch (widget.languageCode) {
      case 'ja':
        return '初回訪問';
      case 'zh':
        return '首次访问';
      default:
        return 'First visit';
    }
  }

  String _getLocalizedJumpToNode() {
    switch (widget.languageCode) {
      case 'ja':
        return 'このシーンへジャンプ';
      case 'zh':
        return '跳转到此场景';
      default:
        return 'Jump to this scene';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }
}

/// Helper class for BFS level assignment
class _NodeLevel {
  final String nodeId;
  final int level;
  _NodeLevel(this.nodeId, this.level);
}


/// Custom painter for flowchart edges
class _FlowchartPainter extends CustomPainter {
  final FlowchartData flowchartData;
  final FlowchartStateManager stateManager;
  final Map<String, Offset> nodePositions;
  final FlowchartScreenConfig config;
  final bool showOnlyVisited;
  final String? selectedNodeId;

  _FlowchartPainter({
    required this.flowchartData,
    required this.stateManager,
    required this.nodePositions,
    required this.config,
    required this.showOnlyVisited,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    const offsetY = 50.0;

    // Draw edges
    for (final node in flowchartData.nodes) {
      final fromPos = nodePositions[node.id];
      if (fromPos == null) continue;

      final isFromVisited = stateManager.isNodeVisited(node.id);
      if (showOnlyVisited && !isFromVisited) continue;

      for (final childId in node.childIds) {
        final toPos = nodePositions[childId];
        if (toPos == null) continue;

        final isToVisited = stateManager.isNodeVisited(childId);
        if (showOnlyVisited && !isToVisited) continue;

        final isEdgeVisited = stateManager.isEdgeVisited(node.id, childId);
        final isHighlighted = selectedNodeId == node.id || selectedNodeId == childId;

        final paint = Paint()
          ..color = isEdgeVisited
              ? (isHighlighted
                  ? config.visitedEdgeColor
                  : config.visitedEdgeColor.withOpacity(0.7))
              : (isHighlighted
                  ? config.unvisitedEdgeColor
                  : config.unvisitedEdgeColor.withOpacity(0.5))
          ..strokeWidth = isHighlighted ? config.edgeWidth * 1.5 : config.edgeWidth
          ..style = PaintingStyle.stroke;

        // Calculate edge points
        final startX = fromPos.dx + centerX + config.nodeSize.width / 2;
        final startY = fromPos.dy + offsetY + config.nodeSize.height;
        final endX = toPos.dx + centerX + config.nodeSize.width / 2;
        final endY = toPos.dy + offsetY;

        // Draw curved edge
        final path = Path();
        path.moveTo(startX, startY);

        final controlY = (startY + endY) / 2;
        path.cubicTo(
          startX, controlY,
          endX, controlY,
          endX, endY,
        );

        canvas.drawPath(path, paint);

        // Draw arrow head
        _drawArrowHead(canvas, endX, endY, paint, isEdgeVisited);
      }
    }
  }

  void _drawArrowHead(Canvas canvas, double x, double y, Paint paint, bool isVisited) {
    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    final path = Path();
    const arrowSize = 8.0;
    path.moveTo(x, y);
    path.lineTo(x - arrowSize, y - arrowSize);
    path.lineTo(x + arrowSize, y - arrowSize);
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _FlowchartPainter oldDelegate) {
    return oldDelegate.showOnlyVisited != showOnlyVisited ||
        oldDelegate.selectedNodeId != selectedNodeId;
  }
}

/// Widget for individual flowchart node
class _FlowchartNodeWidget extends StatefulWidget {
  final FlowchartNode node;
  final bool isVisited;
  final bool isSelected;
  final FlowchartScreenConfig config;
  final String languageCode;
  final VoidCallback? onTap;

  const _FlowchartNodeWidget({
    required this.node,
    required this.isVisited,
    required this.isSelected,
    required this.config,
    required this.languageCode,
    this.onTap,
  });

  @override
  State<_FlowchartNodeWidget> createState() => _FlowchartNodeWidgetState();
}

class _FlowchartNodeWidgetState extends State<_FlowchartNodeWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final typeColor = widget.config.getNodeTypeColor(widget.node.type);
    final baseColor = widget.isVisited
        ? widget.config.visitedNodeColor
        : widget.config.unvisitedNodeColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.config.nodeSize.width,
          height: widget.config.nodeSize.height,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? typeColor.withOpacity(0.3)
                : (_isHovered
                    ? baseColor.withOpacity(0.3)
                    : baseColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? typeColor
                  : (_isHovered ? baseColor : baseColor.withOpacity(0.5)),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected || _isHovered
                ? [
                    BoxShadow(
                      color: (widget.isSelected ? typeColor : baseColor)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Node type icon
              Icon(
                _getNodeIcon(),
                color: widget.isVisited ? typeColor : widget.config.secondaryTextColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              // Node label
              if (widget.config.showNodeLabels)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.node.getLocalizedLabel(widget.languageCode),
                    style: TextStyle(
                      color: widget.isVisited
                          ? widget.config.textColor
                          : widget.config.secondaryTextColor,
                      fontSize: 10,
                      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNodeIcon() {
    switch (widget.node.type) {
      case FlowchartNodeType.start:
        return Icons.play_circle_outline;
      case FlowchartNodeType.scene:
        return Icons.chat_bubble_outline;
      case FlowchartNodeType.choice:
        return Icons.call_split;
      case FlowchartNodeType.ending:
        return Icons.flag;
      case FlowchartNodeType.jump:
        return Icons.arrow_forward;
      case FlowchartNodeType.condition:
        return Icons.help_outline;
    }
  }
}

/// Flowchart visibility mode
enum FlowchartVisibility {
  /// Always show flowchart
  always,

  /// Show after first playthrough completion
  afterCompletion,

  /// Never show flowchart
  never,
}

/// Extension for FlowchartVisibility localization
extension FlowchartVisibilityExtension on FlowchartVisibility {
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
    FlowchartVisibility.always: 'Always',
    FlowchartVisibility.afterCompletion: 'After Completion',
    FlowchartVisibility.never: 'Never',
  };

  static const _japaneseNames = {
    FlowchartVisibility.always: '常に表示',
    FlowchartVisibility.afterCompletion: 'クリア後',
    FlowchartVisibility.never: '非表示',
  };

  static const _chineseNames = {
    FlowchartVisibility.always: '始终显示',
    FlowchartVisibility.afterCompletion: '通关后',
    FlowchartVisibility.never: '不显示',
  };
}
