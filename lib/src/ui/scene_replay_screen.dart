/// Scene Replay Screen Widget
///
/// Displays all replayable scenes with their unlock status.
/// Provides scene list, thumbnails, and replay playback controls.
/// Requirements: 1.1, 1.3, 1.4, 1.5, 1.6

import 'package:flutter/material.dart';

import '../replay/replay.dart';

/// Configuration for the scene replay screen
class SceneReplayScreenConfig {
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

  /// Locked item overlay color
  final Color lockedOverlayColor;

  /// Progress bar color
  final Color progressBarColor;

  /// Progress bar background color
  final Color progressBarBackgroundColor;

  /// Title font size
  final double titleFontSize;

  /// Items per row (for grid view)
  final int itemsPerRow;

  /// Item spacing
  final double itemSpacing;

  /// Whether to use grid view (false = list view)
  final bool useGridView;

  const SceneReplayScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.accentColor = const Color(0xFF6C63FF),
    this.lockedOverlayColor = const Color(0xCC000000),
    this.progressBarColor = const Color(0xFF4CAF50),
    this.progressBarBackgroundColor = const Color(0xFF333333),
    this.titleFontSize = 28.0,
    this.itemsPerRow = 3,
    this.itemSpacing = 16.0,
    this.useGridView = true,
  });
}

/// Scene replay screen widget
class SceneReplayScreen extends StatefulWidget {
  /// List of scene statuses
  final List<SceneReplayStatus> scenes;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Callback when a scene is selected for replay
  final void Function(ReplayableScene scene)? onSceneSelected;

  /// Configuration
  final SceneReplayScreenConfig config;

  /// Language code for localization
  final String languageCode;

  const SceneReplayScreen({
    super.key,
    required this.scenes,
    this.onBack,
    this.onSceneSelected,
    this.config = const SceneReplayScreenConfig(),
    this.languageCode = 'en',
  });

  @override
  State<SceneReplayScreen> createState() => _SceneReplayScreenState();
}

class _SceneReplayScreenState extends State<SceneReplayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOnlyUnlocked = false;

  List<String> get _categories {
    final cats = widget.scenes
        .map((s) => s.scene.category ?? _getLocalizedUncategorized())
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  Map<String, List<SceneReplayStatus>> get _groupedScenes {
    final grouped = <String, List<SceneReplayStatus>>{};
    for (final status in widget.scenes) {
      final category =
          status.scene.category ?? _getLocalizedUncategorized();
      grouped.putIfAbsent(category, () => []).add(status);
    }
    // Sort each group by order
    for (final list in grouped.values) {
      list.sort((a, b) => a.scene.order.compareTo(b.scene.order));
    }
    return grouped;
  }

  int get _unlockedCount =>
      widget.scenes.where((s) => s.isUnlocked).length;

  double get _completionPercentage {
    if (widget.scenes.isEmpty) return 0.0;
    return _unlockedCount / widget.scenes.length;
  }

  String _getLocalizedUncategorized() {
    switch (widget.languageCode) {
      case 'ja':
        return '未分類';
      case 'zh':
        return '未分类';
      default:
        return 'Uncategorized';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length + 1, // +1 for "All" tab
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressSummary(),
            _buildTabs(),
            _buildFilterToggle(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All scenes tab
                  _buildScenesView(widget.scenes),
                  // Category-specific tabs
                  ..._categories.map((category) {
                    return _buildScenesView(_groupedScenes[category] ?? []);
                  }),
                ],
              ),
            ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.config.panelBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie,
                    color: widget.config.accentColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_unlockedCount/${widget.scenes.length}',
                  style: TextStyle(
                    color: widget.config.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle() {
    switch (widget.languageCode) {
      case 'ja':
        return 'シーン回想';
      case 'zh':
        return '场景回放';
      default:
        return 'Scene Replay';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getLocalizedProgress(),
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(_completionPercentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: widget.config.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _completionPercentage,
              backgroundColor: widget.config.progressBarBackgroundColor,
              valueColor:
                  AlwaysStoppedAnimation<Color>(widget.config.progressBarColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  String _getLocalizedProgress() {
    switch (widget.languageCode) {
      case 'ja':
        return '解放率';
      case 'zh':
        return '解锁进度';
      default:
        return 'Unlocked';
    }
  }

  Widget _buildCategoryBreakdown() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _categories.map((category) {
        final scenes = _groupedScenes[category] ?? [];
        final unlocked = scenes.where((s) => s.isUnlocked).length;
        final total = scenes.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.config.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$category: $unlocked/$total',
              style: TextStyle(
                color: widget.config.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: widget.config.accentColor,
        labelColor: widget.config.textColor,
        unselectedLabelColor: widget.config.secondaryTextColor,
        tabs: [
          Tab(text: _getLocalizedAll()),
          ..._categories.map((category) => Tab(text: category)),
        ],
      ),
    );
  }

  String _getLocalizedAll() {
    switch (widget.languageCode) {
      case 'ja':
        return 'すべて';
      case 'zh':
        return '全部';
      default:
        return 'All';
    }
  }

  Widget _buildFilterToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            _getLocalizedShowOnlyUnlocked(),
            style: TextStyle(
              color: widget.config.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Switch(
            value: _showOnlyUnlocked,
            onChanged: (value) => setState(() => _showOnlyUnlocked = value),
            activeColor: widget.config.accentColor,
          ),
        ],
      ),
    );
  }

  String _getLocalizedShowOnlyUnlocked() {
    switch (widget.languageCode) {
      case 'ja':
        return '解放済みのみ表示';
      case 'zh':
        return '仅显示已解锁';
      default:
        return 'Show only unlocked';
    }
  }

  Widget _buildScenesView(List<SceneReplayStatus> scenes) {
    var items = scenes;
    if (_showOnlyUnlocked) {
      items = items.where((s) => s.isUnlocked).toList();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.config.useGridView) {
      return _buildScenesGrid(items);
    } else {
      return _buildScenesList(items);
    }
  }

  Widget _buildScenesList(List<SceneReplayStatus> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: widget.config.itemSpacing),
          child: _SceneListItem(
            status: items[index],
            config: widget.config,
            languageCode: widget.languageCode,
            onTap: items[index].isUnlocked && widget.onSceneSelected != null
                ? () => widget.onSceneSelected!(items[index].scene)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildScenesGrid(List<SceneReplayStatus> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.config.itemsPerRow,
        crossAxisSpacing: widget.config.itemSpacing,
        mainAxisSpacing: widget.config.itemSpacing,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _SceneGridItem(
          status: items[index],
          config: widget.config,
          languageCode: widget.languageCode,
          onTap: items[index].isUnlocked && widget.onSceneSelected != null
              ? () => widget.onSceneSelected!(items[index].scene)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_outlined,
              size: 64, color: widget.config.secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            _showOnlyUnlocked
                ? _getLocalizedNoScenesUnlocked()
                : _getLocalizedNoScenesAvailable(),
            style: TextStyle(
                color: widget.config.secondaryTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  String _getLocalizedNoScenesUnlocked() {
    switch (widget.languageCode) {
      case 'ja':
        return 'まだシーンが解放されていません';
      case 'zh':
        return '尚未解锁任何场景';
      default:
        return 'No scenes unlocked yet';
    }
  }

  String _getLocalizedNoScenesAvailable() {
    switch (widget.languageCode) {
      case 'ja':
        return 'シーンがありません';
      case 'zh':
        return '没有可用的场景';
      default:
        return 'No scenes available';
    }
  }
}


/// List item for scene display
class _SceneListItem extends StatelessWidget {
  final SceneReplayStatus status;
  final SceneReplayScreenConfig config;
  final String languageCode;
  final VoidCallback? onTap;

  const _SceneListItem({
    required this.status,
    required this.config,
    required this.languageCode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.panelBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: status.isUnlocked
              ? Border.all(color: config.accentColor.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Thumbnail
            _buildThumbnail(),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status.scene.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: config.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.scene.category!,
                        style: TextStyle(
                          color: config.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    status.getDisplayTitle(languageCode),
                    style: TextStyle(
                      color: config.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.getDisplayDescription(languageCode) ?? '',
                    style: TextStyle(
                      color: config.secondaryTextColor,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status.isUnlocked && status.unlockDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_getLocalizedUnlocked()}: ${_formatDate(status.unlockDate!)}',
                      style: TextStyle(
                        color: config.secondaryTextColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Play button
            if (status.isUnlocked)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: config.accentColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 100,
      height: 75,
      decoration: BoxDecoration(
        color: status.isUnlocked
            ? config.accentColor.withOpacity(0.2)
            : config.progressBarBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: status.shouldShowThumbnail
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                status.scene.thumbnailPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultIcon(),
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      status.isUnlocked ? Icons.movie : Icons.lock,
      color: status.isUnlocked ? config.accentColor : config.secondaryTextColor,
      size: 32,
    );
  }

  String _getLocalizedUnlocked() {
    switch (languageCode) {
      case 'ja':
        return '解放日';
      case 'zh':
        return '解锁日期';
      default:
        return 'Unlocked';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Grid item for scene display
class _SceneGridItem extends StatefulWidget {
  final SceneReplayStatus status;
  final SceneReplayScreenConfig config;
  final String languageCode;
  final VoidCallback? onTap;

  const _SceneGridItem({
    required this.status,
    required this.config,
    required this.languageCode,
    this.onTap,
  });

  @override
  State<_SceneGridItem> createState() => _SceneGridItemState();
}

class _SceneGridItemState extends State<_SceneGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.config.panelBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered || widget.status.isUnlocked
                  ? widget.config.accentColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail area
              Expanded(
                flex: 3,
                child: _buildThumbnail(),
              ),
              // Info area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.status.scene.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: widget.config.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.status.scene.category!,
                            style: TextStyle(
                              color: widget.config.accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        widget.status.getDisplayTitle(widget.languageCode),
                        style: TextStyle(
                          color: widget.config.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Text(
                          widget.status.getDisplayDescription(widget.languageCode) ?? '',
                          style: TextStyle(
                            color: widget.config.secondaryTextColor,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background/Thumbnail
        Container(
          decoration: BoxDecoration(
            color: widget.status.isUnlocked
                ? widget.config.accentColor.withOpacity(0.1)
                : widget.config.progressBarBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: widget.status.shouldShowThumbnail
              ? ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    widget.status.scene.thumbnailPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultIcon(),
                  ),
                )
              : _buildDefaultIcon(),
        ),
        // Lock overlay for locked scenes
        if (!widget.status.isUnlocked)
          Container(
            decoration: BoxDecoration(
              color: widget.config.lockedOverlayColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(
                Icons.lock,
                color: widget.config.secondaryTextColor,
                size: 32,
              ),
            ),
          ),
        // Play button overlay for unlocked scenes on hover
        if (widget.status.isUnlocked && _isHovered)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.config.accentColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultIcon() {
    return Center(
      child: Icon(
        Icons.movie,
        color: widget.config.accentColor,
        size: 40,
      ),
    );
  }
}

/// Scene replay player widget
/// Provides playback controls during scene replay
class SceneReplayPlayer extends StatefulWidget {
  /// Scene being replayed
  final ReplayableScene scene;

  /// Callback when replay is complete
  final VoidCallback? onComplete;

  /// Callback when replay is cancelled
  final VoidCallback? onCancel;

  /// Callback to skip forward
  final VoidCallback? onSkip;

  /// Callback to toggle auto-play
  final void Function(bool enabled)? onAutoPlayToggle;

  /// Current auto-play state
  final bool isAutoPlaying;

  /// Current playback speed
  final double playbackSpeed;

  /// Callback to change playback speed
  final void Function(double speed)? onSpeedChange;

  /// Configuration
  final SceneReplayScreenConfig config;

  /// Language code for localization
  final String languageCode;

  const SceneReplayPlayer({
    super.key,
    required this.scene,
    this.onComplete,
    this.onCancel,
    this.onSkip,
    this.onAutoPlayToggle,
    this.isAutoPlaying = false,
    this.playbackSpeed = 1.0,
    this.onSpeedChange,
    this.config = const SceneReplayScreenConfig(),
    this.languageCode = 'en',
  });

  @override
  State<SceneReplayPlayer> createState() => _SceneReplayPlayerState();
}

class _SceneReplayPlayerState extends State<SceneReplayPlayer> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        children: [
          // Controls overlay
          if (_showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildControlsBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel button
            IconButton(
              icon: Icon(Icons.close, color: widget.config.textColor),
              onPressed: widget.onCancel,
              tooltip: _getLocalizedCancel(),
            ),
            const SizedBox(width: 8),
            // Scene title
            Expanded(
              child: Text(
                widget.scene.getLocalizedTitle(widget.languageCode),
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Auto-play toggle
            IconButton(
              icon: Icon(
                widget.isAutoPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.config.textColor,
              ),
              onPressed: () =>
                  widget.onAutoPlayToggle?.call(!widget.isAutoPlaying),
              tooltip: widget.isAutoPlaying
                  ? _getLocalizedPause()
                  : _getLocalizedAutoPlay(),
            ),
            // Skip button
            IconButton(
              icon: Icon(Icons.skip_next, color: widget.config.textColor),
              onPressed: widget.onSkip,
              tooltip: _getLocalizedSkip(),
            ),
            // Speed selector
            PopupMenuButton<double>(
              icon: Icon(Icons.speed, color: widget.config.textColor),
              tooltip: _getLocalizedSpeed(),
              onSelected: widget.onSpeedChange,
              itemBuilder: (context) => [
                _buildSpeedMenuItem(0.5),
                _buildSpeedMenuItem(1.0),
                _buildSpeedMenuItem(1.5),
                _buildSpeedMenuItem(2.0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<double> _buildSpeedMenuItem(double speed) {
    final isSelected = widget.playbackSpeed == speed;
    return PopupMenuItem<double>(
      value: speed,
      child: Row(
        children: [
          if (isSelected)
            Icon(Icons.check, color: widget.config.accentColor, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text('${speed}x'),
        ],
      ),
    );
  }

  String _getLocalizedCancel() {
    switch (widget.languageCode) {
      case 'ja':
        return '終了';
      case 'zh':
        return '退出';
      default:
        return 'Exit';
    }
  }

  String _getLocalizedAutoPlay() {
    switch (widget.languageCode) {
      case 'ja':
        return '自動再生';
      case 'zh':
        return '自动播放';
      default:
        return 'Auto-play';
    }
  }

  String _getLocalizedPause() {
    switch (widget.languageCode) {
      case 'ja':
        return '一時停止';
      case 'zh':
        return '暂停';
      default:
        return 'Pause';
    }
  }

  String _getLocalizedSkip() {
    switch (widget.languageCode) {
      case 'ja':
        return 'スキップ';
      case 'zh':
        return '跳过';
      default:
        return 'Skip';
    }
  }

  String _getLocalizedSpeed() {
    switch (widget.languageCode) {
      case 'ja':
        return '再生速度';
      case 'zh':
        return '播放速度';
      default:
        return 'Speed';
    }
  }
}

/// Scene unlocked notification popup
class SceneUnlockedNotification extends StatefulWidget {
  final ReplayableScene scene;
  final VoidCallback? onDismiss;
  final VoidCallback? onReplayNow;
  final Duration displayDuration;
  final String languageCode;
  final SceneReplayScreenConfig config;

  const SceneUnlockedNotification({
    super.key,
    required this.scene,
    this.onDismiss,
    this.onReplayNow,
    this.displayDuration = const Duration(seconds: 5),
    this.languageCode = 'en',
    this.config = const SceneReplayScreenConfig(),
  });

  @override
  State<SceneUnlockedNotification> createState() =>
      _SceneUnlockedNotificationState();
}

class _SceneUnlockedNotificationState extends State<SceneUnlockedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.config.panelBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.config.accentColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.config.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.movie,
                color: widget.config.accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLocalizedSceneUnlocked(),
                    style: TextStyle(
                      color: widget.config.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.scene.getLocalizedTitle(widget.languageCode),
                    style: TextStyle(
                      color: widget.config.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (widget.onReplayNow != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: widget.onReplayNow,
                child: Text(
                  _getLocalizedReplayNow(),
                  style: TextStyle(
                    color: widget.config.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLocalizedSceneUnlocked() {
    switch (widget.languageCode) {
      case 'ja':
        return 'シーン解放';
      case 'zh':
        return '场景已解锁';
      default:
        return 'Scene Unlocked';
    }
  }

  String _getLocalizedReplayNow() {
    switch (widget.languageCode) {
      case 'ja':
        return '今すぐ再生';
      case 'zh':
        return '立即播放';
      default:
        return 'Replay Now';
    }
  }
}
