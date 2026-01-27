/// Affection UI Widgets for VNBS
///
/// Provides UI components for displaying and notifying affection changes.
/// Requirements: 18.2, 18.3

import 'package:flutter/material.dart';

import '../affection/affection.dart';

/// Configuration for affection UI components
class AffectionUIConfig {
  /// Background color for panels
  final Color panelBackgroundColor;

  /// Text color
  final Color textColor;

  /// Secondary text color
  final Color secondaryTextColor;

  /// Progress bar background color
  final Color progressBarBackgroundColor;

  /// Positive change color (affection increase)
  final Color positiveChangeColor;

  /// Negative change color (affection decrease)
  final Color negativeChangeColor;

  /// Notification display duration
  final Duration notificationDuration;

  /// Whether to show heart animation on increase
  final bool showHeartAnimation;

  const AffectionUIConfig({
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.progressBarBackgroundColor = const Color(0xFF333333),
    this.positiveChangeColor = const Color(0xFFFF69B4),
    this.negativeChangeColor = const Color(0xFF6495ED),
    this.notificationDuration = const Duration(seconds: 3),
    this.showHeartAnimation = true,
  });
}

/// Affection change notification popup
///
/// Shows when affection value changes, with optional threshold crossing info.
class AffectionChangeNotification extends StatefulWidget {
  /// The affection change event
  final AffectionChangeEvent event;

  /// The affection definition for display info
  final AffectionDefinition definition;

  /// Callback when notification is dismissed
  final VoidCallback? onDismiss;

  /// Configuration
  final AffectionUIConfig config;

  /// Language code for localization
  final String languageCode;

  const AffectionChangeNotification({
    super.key,
    required this.event,
    required this.definition,
    this.onDismiss,
    this.config = const AffectionUIConfig(),
    this.languageCode = 'en',
  });

  @override
  State<AffectionChangeNotification> createState() =>
      _AffectionChangeNotificationState();
}

class _AffectionChangeNotificationState
    extends State<AffectionChangeNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(widget.config.notificationDuration, () {
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

  Color get _changeColor => widget.event.isIncrease
      ? widget.config.positiveChangeColor
      : widget.config.negativeChangeColor;

  String get _changeText {
    final delta = widget.event.delta;
    return delta > 0 ? '+$delta' : '$delta';
  }

  IconData get _changeIcon {
    if (widget.event.isIncrease) {
      return Icons.favorite;
    } else {
      return Icons.heart_broken;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _changeColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: _changeColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Heart icon with animation
          _buildHeartIcon(),
          const SizedBox(width: 12),
          // Character name and change
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.definition.getLocalizedName(widget.languageCode),
                style: TextStyle(
                  color: widget.config.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.definition.typeLabel,
                    style: TextStyle(
                      color: widget.config.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _changeText,
                    style: TextStyle(
                      color: _changeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Threshold crossing indicator
          if (widget.event.hasCrossedThresholds) ...[
            const SizedBox(width: 16),
            _buildThresholdBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeartIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.2),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: widget.config.showHeartAnimation ? scale : 1.0,
          child: Icon(
            _changeIcon,
            color: _changeColor,
            size: 32,
          ),
        );
      },
    );
  }

  Widget _buildThresholdBadge() {
    final threshold = widget.event.crossedThresholds.last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _changeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        threshold.getLocalizedLabel(widget.languageCode),
        style: TextStyle(
          color: _changeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Affection meter widget
///
/// Displays current affection level with progress bar and threshold labels.
class AffectionMeter extends StatelessWidget {
  /// The affection status to display
  final AffectionStatus status;

  /// Configuration
  final AffectionUIConfig config;

  /// Language code for localization
  final String languageCode;

  /// Whether to show the character name
  final bool showName;

  /// Whether to show the current threshold label
  final bool showThresholdLabel;

  /// Whether to show numeric value
  final bool showValue;

  /// Width of the meter (null = expand to fill)
  final double? width;

  /// Height of the progress bar
  final double barHeight;

  const AffectionMeter({
    super.key,
    required this.status,
    this.config = const AffectionUIConfig(),
    this.languageCode = 'en',
    this.showName = true,
    this.showThresholdLabel = true,
    this.showValue = false,
    this.width,
    this.barHeight = 8.0,
  });

  Color get _meterColor {
    // Parse color from definition or use default
    final hexColor = status.definition.color;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return config.positiveChangeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              // Icon
              Icon(
                _getRelationshipIcon(),
                color: _meterColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              // Name and type
              if (showName)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.definition
                            .getLocalizedName(languageCode),
                        style: TextStyle(
                          color: config.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        status.definition.typeLabel,
                        style: TextStyle(
                          color: config.secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              // Value or threshold label
              if (showValue)
                Text(
                  '${status.currentValue}/${status.definition.maxValue}',
                  style: TextStyle(
                    color: _meterColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (showThresholdLabel && status.currentLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _meterColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.currentLabel!,
                    style: TextStyle(
                      color: _meterColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          _buildProgressBar(),
          // Next threshold info
          if (status.nextThreshold != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next: ${status.nextLabel}',
                  style: TextStyle(
                    color: config.secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${status.pointsToNext} more',
                  style: TextStyle(
                    color: config.secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(barHeight / 2),
      child: Stack(
        children: [
          // Background
          Container(
            height: barHeight,
            color: config.progressBarBackgroundColor,
          ),
          // Progress
          FractionallySizedBox(
            widthFactor: status.percentage,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _meterColor.withOpacity(0.7),
                    _meterColor,
                  ],
                ),
              ),
            ),
          ),
          // Threshold markers
          ..._buildThresholdMarkers(),
        ],
      ),
    );
  }

  List<Widget> _buildThresholdMarkers() {
    final markers = <Widget>[];
    final def = status.definition;
    final range = def.maxValue - def.minValue;

    if (range <= 0) return markers;

    for (final threshold in def.thresholds) {
      final position = (threshold.value - def.minValue) / range;
      if (position > 0 && position < 1) {
        markers.add(
          Positioned(
            left: 0,
            right: 0,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: position,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 2,
                  height: barHeight,
                  color: config.textColor.withOpacity(0.3),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  IconData _getRelationshipIcon() {
    switch (status.definition.type) {
      case RelationshipType.love:
        return Icons.favorite;
      case RelationshipType.friendship:
        return Icons.people;
      case RelationshipType.rivalry:
        return Icons.flash_on;
      case RelationshipType.trust:
        return Icons.shield;
      case RelationshipType.custom:
        return Icons.star;
    }
  }
}

/// Compact affection indicator for HUD display
class AffectionIndicator extends StatelessWidget {
  /// The affection status to display
  final AffectionStatus status;

  /// Configuration
  final AffectionUIConfig config;

  /// Size of the indicator
  final double size;

  const AffectionIndicator({
    super.key,
    required this.status,
    this.config = const AffectionUIConfig(),
    this.size = 48,
  });

  Color get _meterColor {
    final hexColor = status.definition.color;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return config.positiveChangeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: status.percentage,
              backgroundColor: config.progressBarBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(_meterColor),
              strokeWidth: 3,
            ),
          ),
          // Icon
          Icon(
            _getRelationshipIcon(),
            color: _meterColor,
            size: size * 0.4,
          ),
        ],
      ),
    );
  }

  IconData _getRelationshipIcon() {
    switch (status.definition.type) {
      case RelationshipType.love:
        return Icons.favorite;
      case RelationshipType.friendship:
        return Icons.people;
      case RelationshipType.rivalry:
        return Icons.flash_on;
      case RelationshipType.trust:
        return Icons.shield;
      case RelationshipType.custom:
        return Icons.star;
    }
  }
}

/// Overlay manager for showing affection change notifications
class AffectionNotificationOverlay {
  static OverlayEntry? _currentEntry;

  /// Show an affection change notification
  static void show(
    BuildContext context,
    AffectionChangeEvent event,
    AffectionDefinition definition, {
    String languageCode = 'en',
    AffectionUIConfig config = const AffectionUIConfig(),
  }) {
    // Don't show if changes are disabled for this character
    if (!definition.showChanges) return;

    // Remove any existing notification
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 100,
        left: 0,
        right: 0,
        child: Center(
          child: AffectionChangeNotification(
            event: event,
            definition: definition,
            config: config,
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

/// Affection status panel showing all characters
class AffectionStatusPanel extends StatelessWidget {
  /// List of affection statuses
  final List<AffectionStatus> statuses;

  /// Configuration
  final AffectionUIConfig config;

  /// Language code for localization
  final String languageCode;

  /// Callback when a character is tapped
  final void Function(AffectionStatus)? onCharacterTap;

  const AffectionStatusPanel({
    super.key,
    required this.statuses,
    this.config = const AffectionUIConfig(),
    this.languageCode = 'en',
    this.onCharacterTap,
  });

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: statuses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final status = statuses[index];
        return GestureDetector(
          onTap: onCharacterTap != null ? () => onCharacterTap!(status) : null,
          child: AffectionMeter(
            status: status,
            config: config,
            languageCode: languageCode,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: config.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No relationships tracked',
            style: TextStyle(
              color: config.secondaryTextColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
