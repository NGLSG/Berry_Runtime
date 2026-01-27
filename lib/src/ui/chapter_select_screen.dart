/// Chapter Select Screen Widget
///
/// Displays chapter selection with unlock status and New Game+ options.
/// Requirements: 8.1, 8.2, 8.3, 8.6

import 'package:flutter/material.dart';

import '../newgameplus/newgameplus.dart';

/// Configuration for the chapter select screen
class ChapterSelectScreenConfig {
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

  /// New Game+ button color
  final Color newGamePlusColor;

  /// Completed chapter indicator color
  final Color completedColor;

  const ChapterSelectScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.accentColor = const Color(0xFF6C63FF),
    this.lockedOverlayColor = const Color(0xCC000000),
    this.progressBarColor = const Color(0xFF4CAF50),
    this.progressBarBackgroundColor = const Color(0xFF333333),
    this.titleFontSize = 28.0,
    this.itemsPerRow = 2,
    this.itemSpacing = 16.0,
    this.useGridView = true,
    this.newGamePlusColor = const Color(0xFFFFD700),
    this.completedColor = const Color(0xFF4CAF50),
  });
}

/// Chapter select screen widget
class ChapterSelectScreen extends StatefulWidget {
  /// List of chapter statuses
  final List<ChapterSelectStatus> chapters;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Callback when a chapter is selected
  final void Function(ChapterInfo chapter)? onChapterSelected;

  /// Callback when New Game+ is selected
  final VoidCallback? onNewGamePlusSelected;

  /// Whether New Game+ is available
  final bool isNewGamePlusAvailable;

  /// Current New Game+ count (0 = first playthrough)
  final int newGamePlusCount;

  /// Configuration
  final ChapterSelectScreenConfig config;

  /// Language code for localization
  final String languageCode;

  const ChapterSelectScreen({
    super.key,
    required this.chapters,
    this.onBack,
    this.onChapterSelected,
    this.onNewGamePlusSelected,
    this.isNewGamePlusAvailable = false,
    this.newGamePlusCount = 0,
    this.config = const ChapterSelectScreenConfig(),
    this.languageCode = 'en',
  });

  @override
  State<ChapterSelectScreen> createState() => _ChapterSelectScreenState();
}

class _ChapterSelectScreenState extends State<ChapterSelectScreen> {
  bool _showOnlyUnlocked = false;

  int get _unlockedCount =>
      widget.chapters.where((s) => s.isUnlocked).length;

  int get _completedCount =>
      widget.chapters.where((s) => s.isCompleted).length;

  double get _completionPercentage {
    if (widget.chapters.isEmpty) return 0.0;
    return _completedCount / widget.chapters.length;
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
            if (widget.isNewGamePlusAvailable) _buildNewGamePlusButton(),
            _buildFilterToggle(),
            Expanded(child: _buildChapterList()),
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
          if (widget.newGamePlusCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.config.newGamePlusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.config.newGamePlusColor.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star,
                      color: widget.config.newGamePlusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'NG+${widget.newGamePlusCount}',
                    style: TextStyle(
                      color: widget.config.newGamePlusColor,
                      fontSize: 12,
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
        return 'チャプター選択';
      case 'zh':
        return '章节选择';
      default:
        return 'Chapter Select';
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
                '${(_completionPercentage * 100).toStringAsFixed(0)}%',
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
              valueColor: AlwaysStoppedAnimation<Color>(
                  widget.config.progressBarColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBadge(
                icon: Icons.lock_open,
                label: _getLocalizedUnlocked(),
                value: '$_unlockedCount/${widget.chapters.length}',
                color: widget.config.accentColor,
              ),
              const SizedBox(width: 16),
              _buildStatBadge(
                icon: Icons.check_circle,
                label: _getLocalizedCompleted(),
                value: '$_completedCount/${widget.chapters.length}',
                color: widget.config.completedColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: TextStyle(
            color: widget.config.secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getLocalizedProgress() {
    switch (widget.languageCode) {
      case 'ja':
        return '進行状況';
      case 'zh':
        return '进度';
      default:
        return 'Progress';
    }
  }

  String _getLocalizedUnlocked() {
    switch (widget.languageCode) {
      case 'ja':
        return '解放済み';
      case 'zh':
        return '已解锁';
      default:
        return 'Unlocked';
    }
  }

  String _getLocalizedCompleted() {
    switch (widget.languageCode) {
      case 'ja':
        return '完了';
      case 'zh':
        return '已完成';
      default:
        return 'Completed';
    }
  }

  Widget _buildNewGamePlusButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onNewGamePlusSelected,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.config.newGamePlusColor.withOpacity(0.3),
                  widget.config.newGamePlusColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.config.newGamePlusColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.config.newGamePlusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.replay,
                    color: widget.config.newGamePlusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLocalizedNewGamePlus(),
                        style: TextStyle(
                          color: widget.config.newGamePlusColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLocalizedNewGamePlusDescription(),
                        style: TextStyle(
                          color: widget.config.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: widget.config.newGamePlusColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalizedNewGamePlus() {
    switch (widget.languageCode) {
      case 'ja':
        return 'New Game+';
      case 'zh':
        return '新游戏+';
      default:
        return 'New Game+';
    }
  }

  String _getLocalizedNewGamePlusDescription() {
    switch (widget.languageCode) {
      case 'ja':
        return '進行状況を引き継いで最初から始める';
      case 'zh':
        return '继承进度从头开始';
      default:
        return 'Start from the beginning with carried over progress';
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

  Widget _buildChapterList() {
    var items = widget.chapters;
    if (_showOnlyUnlocked) {
      items = items.where((s) => s.isUnlocked).toList();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.config.useGridView) {
      return _buildChapterGrid(items);
    } else {
      return _buildChapterListView(items);
    }
  }

  Widget _buildChapterListView(List<ChapterSelectStatus> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: widget.config.itemSpacing),
          child: _ChapterListItem(
            status: items[index],
            config: widget.config,
            languageCode: widget.languageCode,
            onTap: items[index].isUnlocked && widget.onChapterSelected != null
                ? () => widget.onChapterSelected!(items[index].chapter)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildChapterGrid(List<ChapterSelectStatus> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.config.itemsPerRow,
        crossAxisSpacing: widget.config.itemSpacing,
        mainAxisSpacing: widget.config.itemSpacing,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _ChapterGridItem(
          status: items[index],
          config: widget.config,
          languageCode: widget.languageCode,
          onTap: items[index].isUnlocked && widget.onChapterSelected != null
              ? () => widget.onChapterSelected!(items[index].chapter)
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
          Icon(Icons.menu_book_outlined,
              size: 64, color: widget.config.secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            _getLocalizedNoChapters(),
            style: TextStyle(
                color: widget.config.secondaryTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  String _getLocalizedNoChapters() {
    switch (widget.languageCode) {
      case 'ja':
        return 'チャプターがありません';
      case 'zh':
        return '没有可用的章节';
      default:
        return 'No chapters available';
    }
  }
}


/// List item for chapter display
class _ChapterListItem extends StatelessWidget {
  final ChapterSelectStatus status;
  final ChapterSelectScreenConfig config;
  final String languageCode;
  final VoidCallback? onTap;

  const _ChapterListItem({
    required this.status,
    required this.config,
    required this.languageCode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chapter = status.chapter;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.panelBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: status.isUnlocked
              ? Border.all(
                  color: status.isCompleted
                      ? config.completedColor.withOpacity(0.5)
                      : config.accentColor.withOpacity(0.3),
                  width: 1,
                )
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
                  Row(
                    children: [
                      // Chapter number badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_getLocalizedChapter()} ${chapter.order + 1}',
                          style: TextStyle(
                            color: config.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (status.isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: config.completedColor,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chapter.title,
                    style: TextStyle(
                      color: status.isUnlocked
                          ? config.textColor
                          : config.secondaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (chapter.description != null && status.isUnlocked) ...[
                    const SizedBox(height: 4),
                    Text(
                      chapter.description!,
                      style: TextStyle(
                        color: config.secondaryTextColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (chapter.estimatedPlayTime != null && status.isUnlocked) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: config.secondaryTextColor.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chapter.formattedPlayTime,
                          style: TextStyle(
                            color: config.secondaryTextColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow indicator
            if (status.isUnlocked)
              Icon(
                Icons.arrow_forward_ios,
                color: config.secondaryTextColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: status.isUnlocked
            ? config.accentColor.withOpacity(0.2)
            : config.progressBarBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: status.isUnlocked && status.chapter.thumbnailPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                status.chapter.thumbnailPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultIcon(),
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      status.isUnlocked ? Icons.menu_book : Icons.lock,
      color: status.isUnlocked
          ? config.accentColor
          : config.secondaryTextColor,
      size: 32,
    );
  }

  String _getLocalizedChapter() {
    switch (languageCode) {
      case 'ja':
        return '第';
      case 'zh':
        return '第';
      default:
        return 'Ch.';
    }
  }
}

/// Grid item for chapter display
class _ChapterGridItem extends StatefulWidget {
  final ChapterSelectStatus status;
  final ChapterSelectScreenConfig config;
  final String languageCode;
  final VoidCallback? onTap;

  const _ChapterGridItem({
    required this.status,
    required this.config,
    required this.languageCode,
    this.onTap,
  });

  @override
  State<_ChapterGridItem> createState() => _ChapterGridItemState();
}

class _ChapterGridItemState extends State<_ChapterGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.status.chapter;

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
              color: _isHovered && widget.status.isUnlocked
                  ? widget.config.accentColor.withOpacity(0.5)
                  : widget.status.isCompleted
                      ? widget.config.completedColor.withOpacity(0.3)
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
                      Row(
                        children: [
                          // Chapter number badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.config.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_getLocalizedChapter()} ${chapter.order + 1}',
                              style: TextStyle(
                                color: widget.config.accentColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (widget.status.isCompleted)
                            Icon(
                              Icons.check_circle,
                              color: widget.config.completedColor,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chapter.title,
                        style: TextStyle(
                          color: widget.status.isUnlocked
                              ? widget.config.textColor
                              : widget.config.secondaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (chapter.estimatedPlayTime != null &&
                          widget.status.isUnlocked)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: widget.config.secondaryTextColor
                                  .withOpacity(0.7),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              chapter.formattedPlayTime,
                              style: TextStyle(
                                color: widget.config.secondaryTextColor
                                    .withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: widget.status.isUnlocked &&
                  widget.status.chapter.thumbnailPath != null
              ? ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    widget.status.chapter.thumbnailPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultIcon(),
                  ),
                )
              : _buildDefaultIcon(),
        ),
        // Lock overlay for locked chapters
        if (!widget.status.isUnlocked)
          Container(
            decoration: BoxDecoration(
              color: widget.config.lockedOverlayColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(
                Icons.lock,
                color: widget.config.secondaryTextColor,
                size: 32,
              ),
            ),
          ),
        // Completed overlay
        if (widget.status.isCompleted)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.config.completedColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultIcon() {
    return Center(
      child: Icon(
        Icons.menu_book,
        color: widget.config.accentColor,
        size: 40,
      ),
    );
  }

  String _getLocalizedChapter() {
    switch (widget.languageCode) {
      case 'ja':
        return '第';
      case 'zh':
        return '第';
      default:
        return 'Ch.';
    }
  }
}

/// New Game+ confirmation dialog
class NewGamePlusDialog extends StatelessWidget {
  final NewGamePlusConfig config;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String languageCode;
  final ChapterSelectScreenConfig screenConfig;

  const NewGamePlusDialog({
    super.key,
    required this.config,
    this.onConfirm,
    this.onCancel,
    this.languageCode = 'en',
    this.screenConfig = const ChapterSelectScreenConfig(),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: screenConfig.panelBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: screenConfig.newGamePlusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.replay,
                color: screenConfig.newGamePlusColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              _getLocalizedTitle(),
              style: TextStyle(
                color: screenConfig.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              _getLocalizedDescription(),
              style: TextStyle(
                color: screenConfig.secondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Carryover info
            _buildCarryoverInfo(),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: screenConfig.secondaryTextColor,
                      side: BorderSide(
                          color: screenConfig.secondaryTextColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(_getLocalizedCancel()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: screenConfig.newGamePlusColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(_getLocalizedStart()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarryoverInfo() {
    final items = <Widget>[];

    if (config.carryOverVariables.isNotEmpty) {
      items.add(_buildCarryoverItem(
        Icons.data_object,
        _getLocalizedVariables(),
        '${config.carryOverVariables.length} ${_getLocalizedItems()}',
      ));
    }

    if (config.carryOverReadState) {
      items.add(_buildCarryoverItem(
        Icons.visibility,
        _getLocalizedReadState(),
        _getLocalizedEnabled(),
      ));
    }

    if (config.carryOverAffection) {
      items.add(_buildCarryoverItem(
        Icons.favorite,
        _getLocalizedAffection(),
        _getLocalizedEnabled(),
      ));
    }

    if (config.carryOverUnlocks) {
      items.add(_buildCarryoverItem(
        Icons.lock_open,
        _getLocalizedUnlocks(),
        _getLocalizedEnabled(),
      ));
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: screenConfig.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedCarryover(),
            style: TextStyle(
              color: screenConfig.textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildCarryoverItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: screenConfig.accentColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: screenConfig.secondaryTextColor,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: screenConfig.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle() {
    switch (languageCode) {
      case 'ja':
        return 'New Game+ を開始';
      case 'zh':
        return '开始新游戏+';
      default:
        return 'Start New Game+';
    }
  }

  String _getLocalizedDescription() {
    switch (languageCode) {
      case 'ja':
        return '進行状況を引き継いで最初から始めます。';
      case 'zh':
        return '继承进度从头开始游戏。';
      default:
        return 'Start from the beginning with your progress carried over.';
    }
  }

  String _getLocalizedCarryover() {
    switch (languageCode) {
      case 'ja':
        return '引き継ぎ内容:';
      case 'zh':
        return '继承内容:';
      default:
        return 'Carryover:';
    }
  }

  String _getLocalizedVariables() {
    switch (languageCode) {
      case 'ja':
        return '変数';
      case 'zh':
        return '变量';
      default:
        return 'Variables';
    }
  }

  String _getLocalizedReadState() {
    switch (languageCode) {
      case 'ja':
        return '既読状態';
      case 'zh':
        return '已读状态';
      default:
        return 'Read State';
    }
  }

  String _getLocalizedAffection() {
    switch (languageCode) {
      case 'ja':
        return '好感度';
      case 'zh':
        return '好感度';
      default:
        return 'Affection';
    }
  }

  String _getLocalizedUnlocks() {
    switch (languageCode) {
      case 'ja':
        return '解放済みコンテンツ';
      case 'zh':
        return '已解锁内容';
      default:
        return 'Unlocks';
    }
  }

  String _getLocalizedItems() {
    switch (languageCode) {
      case 'ja':
        return '項目';
      case 'zh':
        return '项';
      default:
        return 'items';
    }
  }

  String _getLocalizedEnabled() {
    switch (languageCode) {
      case 'ja':
        return '有効';
      case 'zh':
        return '启用';
      default:
        return 'Enabled';
    }
  }

  String _getLocalizedCancel() {
    switch (languageCode) {
      case 'ja':
        return 'キャンセル';
      case 'zh':
        return '取消';
      default:
        return 'Cancel';
    }
  }

  String _getLocalizedStart() {
    switch (languageCode) {
      case 'ja':
        return '開始';
      case 'zh':
        return '开始';
      default:
        return 'Start';
    }
  }
}
