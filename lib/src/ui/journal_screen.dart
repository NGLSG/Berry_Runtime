/// Journal Screen Widget
///
/// Displays journal entries in a list layout with type tabs and search.
/// Supports categories, rich text content, and images.
/// Requirements: 19.1-19.4, 19.6

import 'package:flutter/material.dart';

import '../journal/journal.dart';

/// Configuration for the journal screen
class JournalScreenConfig {
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

  /// Item spacing
  final double itemSpacing;

  const JournalScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.accentColor = const Color(0xFF6C63FF),
    this.lockedOverlayColor = const Color(0xCC000000),
    this.progressBarColor = const Color(0xFF4CAF50),
    this.progressBarBackgroundColor = const Color(0xFF333333),
    this.titleFontSize = 28.0,
    this.itemSpacing = 12.0,
  });
}

/// Journal screen widget
class JournalScreen extends StatefulWidget {
  /// Journal manager
  final JournalManager journalManager;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Configuration
  final JournalScreenConfig config;

  /// Language code for localization
  final String languageCode;

  const JournalScreen({
    super.key,
    required this.journalManager,
    this.onBack,
    this.config = const JournalScreenConfig(),
    this.languageCode = 'en',
  });

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  JournalEntryStatus? _selectedEntry;

  final List<JournalEntryType> _types = JournalEntryType.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<JournalEntryStatus> _getEntriesForType(JournalEntryType type) {
    if (_searchQuery.isNotEmpty) {
      return widget.journalManager
          .search(_searchQuery)
          .where((s) => s.entry.type == type)
          .toList();
    }

    final grouped = widget.journalManager.getGroupedByType();
    return grouped[type] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.backgroundColor,
      child: SafeArea(
        child: _selectedEntry != null
            ? _buildDetailView()
            : _buildListView(),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        _buildHeader(),
        _buildProgressSummary(),
        _buildSearchBar(),
        _buildTypeTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _types.map((type) => _buildEntryList(type)).toList(),
          ),
        ),
      ],
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
            'Journal',
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
                Icon(Icons.auto_stories,
                    color: widget.config.accentColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${widget.journalManager.getUnlockedCount()}/${widget.journalManager.getTotalCount()}',
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
    final completion = widget.journalManager.getCompletionPercentage();

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
                'Collection Progress',
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(completion * 100).toStringAsFixed(1)}%',
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
              value: completion,
              backgroundColor: widget.config.progressBarBackgroundColor,
              valueColor:
                  AlwaysStoppedAnimation<Color>(widget.config.progressBarColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: widget.config.textColor),
        decoration: InputDecoration(
          hintText: 'Search entries...',
          hintStyle: TextStyle(color: widget.config.secondaryTextColor),
          prefixIcon: Icon(Icons.search, color: widget.config.secondaryTextColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: widget.config.secondaryTextColor),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: widget.config.accentColor,
        labelColor: widget.config.accentColor,
        unselectedLabelColor: widget.config.secondaryTextColor,
        tabs: _types.map((type) {
          final count = widget.journalManager.getUnlockedCount(type);
          final total = widget.journalManager.getTotalCount(type);
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getIconForType(type), size: 18),
                const SizedBox(width: 8),
                Text(type.displayName),
                const SizedBox(width: 4),
                Text(
                  '($count/$total)',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.config.secondaryTextColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForType(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.character:
        return Icons.person;
      case JournalEntryType.item:
        return Icons.inventory_2;
      case JournalEntryType.lore:
        return Icons.auto_stories;
      case JournalEntryType.event:
        return Icons.event_note;
      case JournalEntryType.tip:
        return Icons.lightbulb;
    }
  }

  Widget _buildEntryList(JournalEntryType type) {
    final entries = _getEntriesForType(type);

    if (entries.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: widget.config.itemSpacing),
          child: _JournalEntryListItem(
            status: entries[index],
            config: widget.config,
            languageCode: widget.languageCode,
            onTap: () {
              if (entries[index].isUnlocked) {
                setState(() {
                  _selectedEntry = entries[index];
                });
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(JournalEntryType type) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForType(type),
            size: 64,
            color: widget.config.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matching entries found'
                : 'No ${type.displayName.toLowerCase()} entries yet',
            style: TextStyle(
              color: widget.config.secondaryTextColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final entry = _selectedEntry!;

    return Column(
      children: [
        _buildDetailHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.entry.imagePath != null) _buildEntryImage(),
                const SizedBox(height: 16),
                _buildEntryContent(),
                if (entry.entry.relatedEntryIds.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildRelatedEntries(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailHeader() {
    final entry = _selectedEntry!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: widget.config.accentColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: widget.config.textColor),
            onPressed: () {
              setState(() {
                _selectedEntry = null;
              });
            },
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.config.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForType(entry.entry.type),
              color: widget.config.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.getDisplayTitle(widget.languageCode),
                  style: TextStyle(
                    color: widget.config.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (entry.entry.category != null)
                  Text(
                    entry.entry.category!,
                    style: TextStyle(
                      color: widget.config.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryImage() {
    final entry = _selectedEntry!;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          entry.entry.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              _getIconForType(entry.entry.type),
              size: 64,
              color: widget.config.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryContent() {
    final entry = _selectedEntry!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        entry.getDisplayContent(widget.languageCode),
        style: TextStyle(
          color: widget.config.textColor,
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildRelatedEntries() {
    final entry = _selectedEntry!;
    final relatedStatuses =
        widget.journalManager.getRelatedEntries(entry.entry.id);

    if (relatedStatuses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Entries',
          style: TextStyle(
            color: widget.config.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...relatedStatuses.map((status) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _JournalEntryListItem(
                status: status,
                config: widget.config,
                languageCode: widget.languageCode,
                compact: true,
                onTap: () {
                  if (status.isUnlocked) {
                    setState(() {
                      _selectedEntry = status;
                    });
                  }
                },
              ),
            )),
      ],
    );
  }
}

/// List item for journal entry display
class _JournalEntryListItem extends StatelessWidget {
  final JournalEntryStatus status;
  final JournalScreenConfig config;
  final String languageCode;
  final VoidCallback? onTap;
  final bool compact;

  const _JournalEntryListItem({
    required this.status,
    required this.config,
    required this.languageCode,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: status.isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: config.panelBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: status.isUnlocked
                ? Border.all(
                    color: config.accentColor.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              _buildIcon(),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.getDisplayTitle(languageCode),
                      style: TextStyle(
                        color: status.isUnlocked
                            ? config.textColor
                            : config.secondaryTextColor,
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!compact && status.isUnlocked) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getPreviewText(),
                        style: TextStyle(
                          color: config.secondaryTextColor,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (!compact && status.entry.category != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.entry.category!,
                          style: TextStyle(
                            color: config.accentColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status.isUnlocked)
                Icon(
                  Icons.chevron_right,
                  color: config.secondaryTextColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconSize = compact ? 40.0 : 48.0;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: status.isUnlocked
            ? config.accentColor.withOpacity(0.2)
            : config.progressBarBackgroundColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: status.entry.imagePath != null && status.isUnlocked
          ? ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 8 : 12),
              child: Image.asset(
                status.entry.imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultIcon(),
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      status.isUnlocked ? _getIconForType(status.entry.type) : Icons.lock,
      color: status.isUnlocked ? config.accentColor : config.secondaryTextColor,
      size: compact ? 20 : 24,
    );
  }

  IconData _getIconForType(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.character:
        return Icons.person;
      case JournalEntryType.item:
        return Icons.inventory_2;
      case JournalEntryType.lore:
        return Icons.auto_stories;
      case JournalEntryType.event:
        return Icons.event_note;
      case JournalEntryType.tip:
        return Icons.lightbulb;
    }
  }

  String _getPreviewText() {
    final content = status.getDisplayContent(languageCode);
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}

/// Journal entry unlock notification popup
class JournalUnlockNotification extends StatefulWidget {
  final JournalEntry entry;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  final String languageCode;

  const JournalUnlockNotification({
    super.key,
    required this.entry,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 3),
    this.languageCode = 'en',
  });

  @override
  State<JournalUnlockNotification> createState() =>
      _JournalUnlockNotificationState();
}

class _JournalUnlockNotificationState extends State<JournalUnlockNotification>
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
            child: Icon(
              _getIconForType(widget.entry.type),
              color: const Color(0xFF6C63FF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New ${widget.entry.type.displayName} Entry!',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.entry.getLocalizedTitle(widget.languageCode),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.character:
        return Icons.person;
      case JournalEntryType.item:
        return Icons.inventory_2;
      case JournalEntryType.lore:
        return Icons.auto_stories;
      case JournalEntryType.event:
        return Icons.event_note;
      case JournalEntryType.tip:
        return Icons.lightbulb;
    }
  }
}

/// Overlay manager for showing journal notifications
class JournalNotificationOverlay {
  static OverlayEntry? _currentEntry;

  /// Show a journal entry unlock notification
  static void show(
    BuildContext context,
    JournalEntry entry, {
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
          child: JournalUnlockNotification(
            entry: entry,
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
