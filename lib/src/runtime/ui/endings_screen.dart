/// Endings Screen Widget
///
/// Displays all endings with their unlock status, grouped by type.
/// Shows completion percentage and reach order.
/// Requirements: 3.2, 3.3

import 'package:flutter/material.dart';

import '../endings/endings.dart';

/// Configuration for the endings screen
class EndingsScreenConfig {
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

  /// Color for True Ending type
  final Color trueEndingColor;

  /// Color for Normal Ending type
  final Color normalEndingColor;

  /// Color for Bad Ending type
  final Color badEndingColor;

  /// Color for Secret Ending type
  final Color secretEndingColor;

  const EndingsScreenConfig({
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
    this.trueEndingColor = const Color(0xFFFFD700),
    this.normalEndingColor = const Color(0xFF4CAF50),
    this.badEndingColor = const Color(0xFFE53935),
    this.secretEndingColor = const Color(0xFF9C27B0),
  });

  /// Get color for ending type
  Color getTypeColor(EndingType type) {
    switch (type) {
      case EndingType.trueEnding:
        return trueEndingColor;
      case EndingType.normal:
        return normalEndingColor;
      case EndingType.bad:
        return badEndingColor;
      case EndingType.secret:
        return secretEndingColor;
    }
  }
}

/// Endings screen widget
class EndingsScreen extends StatefulWidget {
  /// List of ending statuses
  final List<EndingStatus> endings;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Configuration
  final EndingsScreenConfig config;

  /// Language code for localization
  final String languageCode;

  /// Callback when an ending is selected (for details view)
  final void Function(EndingStatus)? onEndingSelected;

  const EndingsScreen({
    super.key,
    required this.endings,
    this.onBack,
    this.config = const EndingsScreenConfig(),
    this.languageCode = 'en',
    this.onEndingSelected,
  });

  @override
  State<EndingsScreen> createState() => _EndingsScreenState();
}

class _EndingsScreenState extends State<EndingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOnlyReached = false;

  List<EndingType> get _availableTypes {
    final types = widget.endings
        .map((e) => e.definition.type)
        .toSet()
        .toList();
    // Sort in a specific order
    types.sort((a, b) {
      const order = [
        EndingType.trueEnding,
        EndingType.normal,
        EndingType.bad,
        EndingType.secret,
      ];
      return order.indexOf(a).compareTo(order.indexOf(b));
    });
    return types;
  }

  Map<EndingType, List<EndingStatus>> get _groupedEndings {
    final grouped = <EndingType, List<EndingStatus>>{};
    for (final status in widget.endings) {
      grouped.putIfAbsent(status.definition.type, () => []).add(status);
    }
    // Sort each group by order
    for (final list in grouped.values) {
      list.sort((a, b) => a.definition.order.compareTo(b.definition.order));
    }
    return grouped;
  }

  int get _reachedCount => widget.endings.where((s) => s.isReached).length;

  double get _completionPercentage {
    if (widget.endings.isEmpty) return 0.0;
    return _reachedCount / widget.endings.length;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _availableTypes.length + 1, // +1 for "All" tab
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
                  // All endings tab
                  _buildEndingsView(widget.endings),
                  // Type-specific tabs
                  ..._availableTypes.map((type) {
                    return _buildEndingsView(_groupedEndings[type] ?? []);
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
                Icon(Icons.flag,
                    color: widget.config.accentColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_reachedCount/${widget.endings.length}',
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
        return 'エンディング';
      case 'zh':
        return '结局';
      default:
        return 'Endings';
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
          _buildTypeBreakdown(),
        ],
      ),
    );
  }

  String _getLocalizedProgress() {
    switch (widget.languageCode) {
      case 'ja':
        return '達成率';
      case 'zh':
        return '完成度';
      default:
        return 'Completion';
    }
  }

  Widget _buildTypeBreakdown() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _availableTypes.map((type) {
        final endings = _groupedEndings[type] ?? [];
        final reached = endings.where((s) => s.isReached).length;
        final total = endings.length;
        final color = widget.config.getTypeColor(type);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${type.getLocalizedName(widget.languageCode)}: $reached/$total',
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
          ..._availableTypes.map((type) {
            return Tab(text: type.getLocalizedName(widget.languageCode));
          }),
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
            _getLocalizedShowOnlyReached(),
            style: TextStyle(
              color: widget.config.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Switch(
            value: _showOnlyReached,
            onChanged: (value) => setState(() => _showOnlyReached = value),
            activeColor: widget.config.accentColor,
          ),
        ],
      ),
    );
  }

  String _getLocalizedShowOnlyReached() {
    switch (widget.languageCode) {
      case 'ja':
        return '達成済みのみ表示';
      case 'zh':
        return '仅显示已达成';
      default:
        return 'Show only reached';
    }
  }

  Widget _buildEndingsView(List<EndingStatus> endings) {
    var items = endings;
    if (_showOnlyReached) {
      items = items.where((s) => s.isReached).toList();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.config.useGridView) {
      return _buildEndingsGrid(items);
    } else {
      return _buildEndingsList(items);
    }
  }

  Widget _buildEndingsList(List<EndingStatus> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: widget.config.itemSpacing),
          child: _EndingListItem(
            status: items[index],
            config: widget.config,
            languageCode: widget.languageCode,
            onTap: widget.onEndingSelected != null
                ? () => widget.onEndingSelected!(items[index])
                : null,
          ),
        );
      },
    );
  }

  Widget _buildEndingsGrid(List<EndingStatus> items) {
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
        return _EndingGridItem(
          status: items[index],
          config: widget.config,
          languageCode: widget.languageCode,
          onTap: widget.onEndingSelected != null
              ? () => widget.onEndingSelected!(items[index])
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
          Icon(Icons.flag_outlined,
              size: 64, color: widget.config.secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            _showOnlyReached
                ? _getLocalizedNoEndingsReached()
                : _getLocalizedNoEndingsAvailable(),
            style: TextStyle(
                color: widget.config.secondaryTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  String _getLocalizedNoEndingsReached() {
    switch (widget.languageCode) {
      case 'ja':
        return 'まだエンディングに到達していません';
      case 'zh':
        return '尚未达成任何结局';
      default:
        return 'No endings reached yet';
    }
  }

  String _getLocalizedNoEndingsAvailable() {
    switch (widget.languageCode) {
      case 'ja':
        return 'エンディングがありません';
      case 'zh':
        return '没有可用的结局';
      default:
        return 'No endings available';
    }
  }
}


/// List item for ending display
class _EndingListItem extends StatelessWidget {
  final EndingStatus status;
  final EndingsScreenConfig config;
  final String languageCode;
  final VoidCallback? onTap;

  const _EndingListItem({
    required this.status,
    required this.config,
    required this.languageCode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final definition = status.definition;
    final typeColor = config.getTypeColor(definition.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.panelBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: status.isReached
              ? Border.all(color: typeColor.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Thumbnail
            _buildThumbnail(typeColor),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          definition.type.getLocalizedName(languageCode),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (status.isReached && status.reachOrder > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: config.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${status.reachOrder}',
                            style: TextStyle(
                              color: config.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status.getDisplayName(languageCode),
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
                  if (status.isReached && status.reachDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_getLocalizedReached()}: ${_formatDate(status.reachDate!)}',
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
      ),
    );
  }

  Widget _buildThumbnail(Color typeColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: status.isReached
            ? typeColor.withOpacity(0.2)
            : config.progressBarBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: status.shouldShowThumbnail && status.definition.thumbnailPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                status.definition.thumbnailPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultIcon(typeColor),
              ),
            )
          : _buildDefaultIcon(typeColor),
    );
  }

  Widget _buildDefaultIcon(Color typeColor) {
    return Icon(
      status.isReached ? Icons.flag : Icons.lock,
      color: status.isReached ? typeColor : config.secondaryTextColor,
      size: 32,
    );
  }

  String _getLocalizedReached() {
    switch (languageCode) {
      case 'ja':
        return '達成日';
      case 'zh':
        return '达成日期';
      default:
        return 'Reached';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Grid item for ending display
class _EndingGridItem extends StatefulWidget {
  final EndingStatus status;
  final EndingsScreenConfig config;
  final String languageCode;
  final VoidCallback? onTap;

  const _EndingGridItem({
    required this.status,
    required this.config,
    required this.languageCode,
    this.onTap,
  });

  @override
  State<_EndingGridItem> createState() => _EndingGridItemState();
}

class _EndingGridItemState extends State<_EndingGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final definition = widget.status.definition;
    final typeColor = widget.config.getTypeColor(definition.type);

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
              color: _isHovered || widget.status.isReached
                  ? typeColor.withOpacity(0.5)
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
                child: _buildThumbnail(typeColor),
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
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              definition.type.getLocalizedName(widget.languageCode),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (widget.status.isReached && widget.status.reachOrder > 0)
                            Text(
                              '#${widget.status.reachOrder}',
                              style: TextStyle(
                                color: widget.config.accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.status.getDisplayName(widget.languageCode),
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

  Widget _buildThumbnail(Color typeColor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background/Thumbnail
        Container(
          decoration: BoxDecoration(
            color: widget.status.isReached
                ? typeColor.withOpacity(0.1)
                : widget.config.progressBarBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: widget.status.shouldShowThumbnail &&
                  widget.status.definition.thumbnailPath != null
              ? ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    widget.status.definition.thumbnailPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultIcon(typeColor),
                  ),
                )
              : _buildDefaultIcon(typeColor),
        ),
        // Lock overlay for unreached endings
        if (!widget.status.isReached)
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
      ],
    );
  }

  Widget _buildDefaultIcon(Color typeColor) {
    return Center(
      child: Icon(
        Icons.flag,
        color: typeColor,
        size: 40,
      ),
    );
  }
}

/// Ending reached notification popup
class EndingReachedNotification extends StatefulWidget {
  final EndingDefinition ending;
  final int reachOrder;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  final String languageCode;
  final EndingsScreenConfig config;

  const EndingReachedNotification({
    super.key,
    required this.ending,
    this.reachOrder = 0,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 5),
    this.languageCode = 'en',
    this.config = const EndingsScreenConfig(),
  });

  @override
  State<EndingReachedNotification> createState() =>
      _EndingReachedNotificationState();
}

class _EndingReachedNotificationState extends State<EndingReachedNotification>
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
    final typeColor = widget.config.getTypeColor(widget.ending.type);

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
          border: Border.all(color: typeColor, width: 2),
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
                color: typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.ending.thumbnailPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        widget.ending.thumbnailPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.flag,
                          color: typeColor,
                          size: 28,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.flag,
                      color: typeColor,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _getLocalizedEndingReached(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.reachOrder > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.config.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${widget.reachOrder}',
                          style: TextStyle(
                            color: widget.config.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.ending.getLocalizedName(widget.languageCode),
                  style: TextStyle(
                    color: widget.config.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.ending.type.getLocalizedName(widget.languageCode),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedEndingReached() {
    switch (widget.languageCode) {
      case 'ja':
        return 'エンディング達成！';
      case 'zh':
        return '结局达成！';
      default:
        return 'Ending Reached!';
    }
  }
}

/// Overlay manager for showing ending notifications
class EndingNotificationOverlay {
  static OverlayEntry? _currentEntry;

  /// Show an ending reached notification
  static void show(
    BuildContext context,
    EndingDefinition ending, {
    int reachOrder = 0,
    String languageCode = 'en',
    EndingsScreenConfig config = const EndingsScreenConfig(),
  }) {
    // Remove any existing notification
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0,
        right: 0,
        child: Center(
          child: EndingReachedNotification(
            ending: ending,
            reachOrder: reachOrder,
            languageCode: languageCode,
            config: config,
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
