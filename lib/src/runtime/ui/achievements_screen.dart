/// Achievements Screen Widget
///
/// Displays achievements in a list/grid layout with progress tracking.
/// Supports categories, hidden achievements, and unlock notifications.
/// Requirements: 2.4, 2.5

import 'package:flutter/material.dart';

import '../achievements/achievements.dart';
import '../localization/vn_ui_strings.dart';

/// Configuration for the achievements screen
class AchievementsScreenConfig {
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

  const AchievementsScreenConfig({
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
    this.useGridView = false,
  });
}

/// Achievements screen widget
class AchievementsScreen extends StatefulWidget {
  /// List of achievement statuses
  final List<AchievementStatus> achievements;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Configuration
  final AchievementsScreenConfig config;

  /// Language code for localization
  final String languageCode;

  /// Total points possible
  final int totalPoints;

  /// Earned points
  final int earnedPoints;

  const AchievementsScreen({
    super.key,
    required this.achievements,
    this.onBack,
    this.config = const AchievementsScreenConfig(),
    this.languageCode = 'en',
    this.totalPoints = 0,
    this.earnedPoints = 0,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String? _selectedCategory;
  bool _showOnlyUnlocked = false;

  List<String> get _categories {
    final cats = widget.achievements
        .map((e) => e.achievement.category)
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  List<AchievementStatus> get _filteredAchievements {
    var items = widget.achievements.where((s) => s.isVisible).toList();

    if (_showOnlyUnlocked) {
      items = items.where((s) => s.isUnlocked).toList();
    }

    if (_selectedCategory != null) {
      items =
          items.where((s) => s.achievement.category == _selectedCategory).toList();
    }

    // Sort: unlocked first, then by name
    items.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }
      return a.achievement.name.compareTo(b.achievement.name);
    });

    return items;
  }

  int get _unlockedCount =>
      widget.achievements.where((s) => s.isUnlocked).length;

  double get _completionPercentage {
    if (widget.achievements.isEmpty) return 0.0;
    return _unlockedCount / widget.achievements.length;
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
            if (_categories.isNotEmpty) _buildCategoryTabs(),
            _buildFilterToggle(),
            Expanded(
              child: widget.config.useGridView
                  ? _buildAchievementsGrid()
                  : _buildAchievementsList(),
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
            VNUILocalizer.get('achievements', widget.languageCode),
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
                Icon(Icons.emoji_events,
                    color: widget.config.accentColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_unlockedCount/${widget.achievements.length}',
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
                VNUILocalizer.get('overallProgress', widget.languageCode),
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
          if (widget.totalPoints > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${widget.earnedPoints} / ${widget.totalPoints} ${VNUILocalizer.get('points', widget.languageCode).replaceAll('+{num} ', '').replaceAll('+{num}', '')}',
                  style: TextStyle(
                    color: widget.config.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryTab(
            label: VNUILocalizer.get('all', widget.languageCode),
            isSelected: _selectedCategory == null,
            config: widget.config,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ..._categories.map((cat) => _CategoryTab(
                label: cat,
                isSelected: _selectedCategory == cat,
                config: widget.config,
                onTap: () => setState(() => _selectedCategory = cat),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            VNUILocalizer.get('showOnlyUnlocked', widget.languageCode),
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

  Widget _buildAchievementsList() {
    final items = _filteredAchievements;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: widget.config.itemSpacing),
          child: _AchievementListItem(
            status: items[index],
            config: widget.config,
            languageCode: widget.languageCode,
          ),
        );
      },
    );
  }

  Widget _buildAchievementsGrid() {
    final items = _filteredAchievements;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.config.itemsPerRow,
        crossAxisSpacing: widget.config.itemSpacing,
        mainAxisSpacing: widget.config.itemSpacing,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _AchievementGridItem(
          status: items[index],
          config: widget.config,
          languageCode: widget.languageCode,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 64, color: widget.config.secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            _showOnlyUnlocked
                ? VNUILocalizer.get('noAchievementsUnlocked', widget.languageCode)
                : VNUILocalizer.get('noAchievementsAvailable', widget.languageCode),
            style: TextStyle(
                color: widget.config.secondaryTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }
}


class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AchievementsScreenConfig config;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: config.panelBackgroundColor,
        selectedColor: config.accentColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : config.secondaryTextColor,
        ),
      ),
    );
  }
}

/// List item for achievement display
class _AchievementListItem extends StatelessWidget {
  final AchievementStatus status;
  final AchievementsScreenConfig config;
  final String languageCode;

  const _AchievementListItem({
    required this.status,
    required this.config,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = status.achievement;

    return Container(
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
          // Icon
          _buildIcon(),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.getDisplayName(languageCode),
                        style: TextStyle(
                          color: config.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (achievement.points > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${achievement.points}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  status.getDisplayDescription(languageCode),
                  style: TextStyle(
                    color: config.secondaryTextColor,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!status.isUnlocked && status.progress > 0) ...[
                  const SizedBox(height: 8),
                  _buildProgressBar(),
                ],
                if (status.isUnlocked && status.unlockDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${VNUILocalizer.get('unlocked', languageCode)} ${_formatDate(status.unlockDate!)}',
                    style: TextStyle(
                      color: config.secondaryTextColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: status.isUnlocked
            ? config.accentColor.withOpacity(0.2)
            : config.progressBarBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: status.achievement.iconPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                status.achievement.iconPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultIcon(),
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      status.isUnlocked ? Icons.emoji_events : Icons.lock,
      color: status.isUnlocked ? config.accentColor : config.secondaryTextColor,
      size: 28,
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              VNUILocalizer.get('progress', languageCode),
              style: TextStyle(
                color: config.secondaryTextColor,
                fontSize: 12,
              ),
            ),
            Text(
              '${(status.progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: config.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: status.progress,
            backgroundColor: config.progressBarBackgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(config.progressBarColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Grid item for achievement display
class _AchievementGridItem extends StatefulWidget {
  final AchievementStatus status;
  final AchievementsScreenConfig config;
  final String languageCode;

  const _AchievementGridItem({
    required this.status,
    required this.config,
    required this.languageCode,
  });

  @override
  State<_AchievementGridItem> createState() => _AchievementGridItemState();
}

class _AchievementGridItemState extends State<_AchievementGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(height: 8),
            Text(
              widget.status.getDisplayName(widget.languageCode),
              style: TextStyle(
                color: widget.config.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!widget.status.isUnlocked && widget.status.progress > 0) ...[
              const SizedBox(height: 8),
              _buildProgressBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: widget.status.isUnlocked
            ? widget.config.accentColor.withOpacity(0.2)
            : widget.config.progressBarBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.status.achievement.iconPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.status.achievement.iconPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultIcon(),
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      widget.status.isUnlocked ? Icons.emoji_events : Icons.lock,
      color: widget.status.isUnlocked
          ? widget.config.accentColor
          : widget.config.secondaryTextColor,
      size: 24,
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: widget.status.progress,
        backgroundColor: widget.config.progressBarBackgroundColor,
        valueColor:
            AlwaysStoppedAnimation<Color>(widget.config.progressBarColor),
        minHeight: 4,
      ),
    );
  }
}

/// Achievement unlock notification popup
class AchievementUnlockNotification extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  final String languageCode;

  const AchievementUnlockNotification({
    super.key,
    required this.achievement,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
    this.languageCode = 'en',
  });

  @override
  State<AchievementUnlockNotification> createState() =>
      _AchievementUnlockNotificationState();
}

class _AchievementUnlockNotificationState
    extends State<AchievementUnlockNotification>
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
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C63FF), width: 2),
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
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.achievement.iconPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      widget.achievement.iconPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF6C63FF),
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.emoji_events,
                    color: Color(0xFF6C63FF),
                    size: 28,
                  ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                VNUILocalizer.get('achievementUnlocked', widget.languageCode),
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.achievement.getLocalizedName(widget.languageCode),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.achievement.points > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      VNUILocalizer.format('points', {'num': '${widget.achievement.points}'}, widget.languageCode),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Overlay manager for showing achievement notifications
class AchievementNotificationOverlay {
  static OverlayEntry? _currentEntry;

  /// Show an achievement unlock notification
  static void show(
    BuildContext context,
    Achievement achievement, {
    String languageCode = 'en',
  }) {
    // Remove any existing notification
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0,
        right: 0,
        child: Center(
          child: AchievementUnlockNotification(
            achievement: achievement,
            languageCode: languageCode,
            onDismiss: () {
              _currentEntry?.remove();
              _currentEntry = null;
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  /// Hide any current notification
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
