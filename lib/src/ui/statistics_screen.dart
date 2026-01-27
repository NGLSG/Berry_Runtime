/// Statistics Screen Widget
///
/// Displays gameplay statistics including play time, dialogue progress,
/// choice distribution, and ending history.
/// Requirements: 7.5

import 'package:flutter/material.dart';

import '../progress/global_progress_manager.dart';
import '../statistics/play_statistics.dart';

/// Configuration for the statistics screen
class StatisticsScreenConfig {
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

  /// Progress bar color
  final Color progressBarColor;

  /// Progress bar background color
  final Color progressBarBackgroundColor;

  /// Title font size
  final double titleFontSize;

  /// Section spacing
  final double sectionSpacing;

  const StatisticsScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.accentColor = const Color(0xFF6C63FF),
    this.progressBarColor = const Color(0xFF4CAF50),
    this.progressBarBackgroundColor = const Color(0xFF333333),
    this.titleFontSize = 28.0,
    this.sectionSpacing = 16.0,
  });
}

/// Statistics screen widget
class StatisticsScreen extends StatelessWidget {
  /// Play statistics instance
  final PlayStatistics statistics;

  /// Total dialogues in the game (for progress calculation)
  final int? totalDialogues;

  /// Total endings in the game (for progress calculation)
  final int? totalEndings;

  /// Choice labels map (choiceNodeId -> label)
  final Map<String, String>? choiceLabels;

  /// Option labels map (choiceNodeId -> {optionId -> label})
  final Map<String, Map<String, String>>? optionLabels;

  /// Callback when back is pressed
  final VoidCallback? onBack;

  /// Configuration
  final StatisticsScreenConfig config;

  /// Language code for localization
  final String languageCode;

  const StatisticsScreen({
    super.key,
    required this.statistics,
    this.totalDialogues,
    this.totalEndings,
    this.choiceLabels,
    this.optionLabels,
    this.onBack,
    this.config = const StatisticsScreenConfig(),
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final summary = statistics.getSummary(
      totalDialogues: totalDialogues,
      totalEndings: totalEndings,
    );

    return Container(
      color: config.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(config.sectionSpacing),
                children: [
                  _buildPlayTimeSection(summary),
                  SizedBox(height: config.sectionSpacing),
                  _buildReadProgressSection(summary),
                  SizedBox(height: config.sectionSpacing),
                  _buildChoiceSection(),
                  SizedBox(height: config.sectionSpacing),
                  _buildEndingSection(summary),
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
            icon: Icon(Icons.arrow_back, color: config.textColor),
            onPressed: onBack,
          ),
          const SizedBox(width: 16),
          Text(
            _getLocalizedString('statistics'),
            style: TextStyle(
              color: config.textColor,
              fontSize: config.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayTimeSection(StatisticsSummary summary) {
    return _StatisticsSection(
      title: _getLocalizedString('playTime'),
      icon: Icons.access_time,
      config: config,
      child: Column(
        children: [
          _StatisticRow(
            label: _getLocalizedString('totalPlayTime'),
            value: summary.formattedPlayTime,
            config: config,
            icon: Icons.timer,
          ),
          const SizedBox(height: 12),
          _buildPlayTimeVisual(summary.totalPlayTime),
        ],
      ),
    );
  }

  Widget _buildPlayTimeVisual(Duration playTime) {
    final hours = playTime.inHours;
    final minutes = playTime.inMinutes.remainder(60);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TimeUnit(
          value: hours,
          label: _getLocalizedString('hours'),
          config: config,
        ),
        _TimeUnit(
          value: minutes,
          label: _getLocalizedString('minutes'),
          config: config,
        ),
      ],
    );
  }

  Widget _buildReadProgressSection(StatisticsSummary summary) {
    return _StatisticsSection(
      title: _getLocalizedString('readProgress'),
      icon: Icons.menu_book,
      config: config,
      child: Column(
        children: [
          _StatisticRow(
            label: _getLocalizedString('dialoguesRead'),
            value: '${summary.uniqueDialoguesRead}${totalDialogues != null ? ' / $totalDialogues' : ''}',
            config: config,
            icon: Icons.chat_bubble_outline,
          ),
          if (summary.readProgress != null) ...[
            const SizedBox(height: 12),
            _ProgressBar(
              progress: summary.readProgress!,
              label: '${(summary.readProgress! * 100).toStringAsFixed(1)}%',
              config: config,
            ),
          ],
          const SizedBox(height: 12),
          _StatisticRow(
            label: _getLocalizedString('totalReads'),
            value: '${summary.totalDialoguesRead}',
            config: config,
            icon: Icons.repeat,
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceSection() {
    final trackedChoices = statistics.trackedChoiceNodeIds.toList();
    
    return _StatisticsSection(
      title: _getLocalizedString('choices'),
      icon: Icons.call_split,
      config: config,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatisticRow(
            label: _getLocalizedString('totalChoicesMade'),
            value: '${statistics.choiceDistribution.values.fold(0, (sum, choices) => sum + choices.values.fold(0, (s, c) => s + c))}',
            config: config,
            icon: Icons.touch_app,
          ),
          _StatisticRow(
            label: _getLocalizedString('uniqueChoicesTracked'),
            value: '${trackedChoices.length}',
            config: config,
            icon: Icons.analytics,
          ),
          if (trackedChoices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _getLocalizedString('choiceDistribution'),
              style: TextStyle(
                color: config.secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...trackedChoices.take(5).map((choiceId) => _buildChoiceDistribution(choiceId)),
            if (trackedChoices.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_getLocalizedString('andMore')} ${trackedChoices.length - 5}...',
                  style: TextStyle(
                    color: config.secondaryTextColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceDistribution(String choiceNodeId) {
    final choiceStats = ChoiceStatistics.fromPlayStatistics(
      statistics,
      choiceNodeId,
      label: choiceLabels?[choiceNodeId],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.progressBarBackgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            choiceStats.label ?? choiceNodeId,
            style: TextStyle(
              color: config.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ...choiceStats.percentages.entries.map((entry) {
            final optionLabel = optionLabels?[choiceNodeId]?[entry.key] ?? entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ChoiceOptionBar(
                label: optionLabel,
                percentage: entry.value,
                count: choiceStats.distribution[entry.key] ?? 0,
                isMostSelected: entry.key == choiceStats.mostSelectedOption,
                config: config,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEndingSection(StatisticsSummary summary) {
    final endingHistory = statistics.endingHistory;
    
    return _StatisticsSection(
      title: _getLocalizedString('endings'),
      icon: Icons.flag,
      config: config,
      child: Column(
        children: [
          _StatisticRow(
            label: _getLocalizedString('uniqueEndingsReached'),
            value: '${summary.endingsReached}${totalEndings != null ? ' / $totalEndings' : ''}',
            config: config,
            icon: Icons.emoji_events,
          ),
          if (summary.endingCompletionProgress != null) ...[
            const SizedBox(height: 12),
            _ProgressBar(
              progress: summary.endingCompletionProgress!,
              label: '${(summary.endingCompletionProgress! * 100).toStringAsFixed(1)}%',
              config: config,
            ),
          ],
          const SizedBox(height: 12),
          _StatisticRow(
            label: _getLocalizedString('totalEndingPlays'),
            value: '${summary.totalEndingPlays}',
            config: config,
            icon: Icons.replay,
            isSecondary: true,
          ),
          if (endingHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _getLocalizedString('recentEndings'),
              style: TextStyle(
                color: config.secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...endingHistory.reversed.take(5).map((record) => _EndingHistoryItem(
              record: record,
              config: config,
            )),
          ],
        ],
      ),
    );
  }

  String _getLocalizedString(String key) {
    const strings = {
      'en': {
        'statistics': 'Statistics',
        'playTime': 'Play Time',
        'totalPlayTime': 'Total Play Time',
        'hours': 'Hours',
        'minutes': 'Minutes',
        'readProgress': 'Read Progress',
        'dialoguesRead': 'Dialogues Read',
        'totalReads': 'Total Reads (incl. re-reads)',
        'choices': 'Choices',
        'totalChoicesMade': 'Total Choices Made',
        'uniqueChoicesTracked': 'Unique Choices Tracked',
        'choiceDistribution': 'Choice Distribution',
        'andMore': 'and',
        'endings': 'Endings',
        'uniqueEndingsReached': 'Unique Endings Reached',
        'totalEndingPlays': 'Total Ending Plays',
        'recentEndings': 'Recent Endings',
      },
      'ja': {
        'statistics': '統計',
        'playTime': 'プレイ時間',
        'totalPlayTime': '総プレイ時間',
        'hours': '時間',
        'minutes': '分',
        'readProgress': '読了進捗',
        'dialoguesRead': '読んだ台詞',
        'totalReads': '総読了数（再読含む）',
        'choices': '選択肢',
        'totalChoicesMade': '選択した回数',
        'uniqueChoicesTracked': '追跡中の選択肢',
        'choiceDistribution': '選択分布',
        'andMore': 'その他',
        'endings': 'エンディング',
        'uniqueEndingsReached': '到達したエンディング',
        'totalEndingPlays': 'エンディング到達回数',
        'recentEndings': '最近のエンディング',
      },
      'zh': {
        'statistics': '统计',
        'playTime': '游玩时间',
        'totalPlayTime': '总游玩时间',
        'hours': '小时',
        'minutes': '分钟',
        'readProgress': '阅读进度',
        'dialoguesRead': '已读对话',
        'totalReads': '总阅读次数（含重读）',
        'choices': '选择',
        'totalChoicesMade': '总选择次数',
        'uniqueChoicesTracked': '追踪的选择',
        'choiceDistribution': '选择分布',
        'andMore': '以及',
        'endings': '结局',
        'uniqueEndingsReached': '已达成结局',
        'totalEndingPlays': '结局达成次数',
        'recentEndings': '最近结局',
      },
    };

    final langStrings = strings[languageCode] ?? strings['en']!;
    return langStrings[key] ?? strings['en']![key] ?? key;
  }
}


/// Statistics section container
class _StatisticsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final StatisticsScreenConfig config;
  final Widget child;

  const _StatisticsSection({
    required this.title,
    required this.icon,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.panelBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: config.accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: config.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Single statistic row
class _StatisticRow extends StatelessWidget {
  final String label;
  final String value;
  final StatisticsScreenConfig config;
  final IconData? icon;
  final bool isSecondary;

  const _StatisticRow({
    required this.label,
    required this.value,
    required this.config,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isSecondary ? config.secondaryTextColor : config.accentColor,
              size: 18,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSecondary ? config.secondaryTextColor : config.textColor,
                fontSize: isSecondary ? 13 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSecondary ? config.secondaryTextColor : config.accentColor,
              fontSize: isSecondary ? 13 : 16,
              fontWeight: isSecondary ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Time unit display
class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final StatisticsScreenConfig config;

  const _TimeUnit({
    required this.value,
    required this.label,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: config.accentColor,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: config.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Progress bar with label
class _ProgressBar extends StatelessWidget {
  final double progress;
  final String label;
  final StatisticsScreenConfig config;

  const _ProgressBar({
    required this.progress,
    required this.label,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: config.secondaryTextColor,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: config.accentColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: config.progressBarBackgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(config.progressBarColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// Choice option bar showing percentage
class _ChoiceOptionBar extends StatelessWidget {
  final String label;
  final double percentage;
  final int count;
  final bool isMostSelected;
  final StatisticsScreenConfig config;

  const _ChoiceOptionBar({
    required this.label,
    required this.percentage,
    required this.count,
    required this.isMostSelected,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isMostSelected ? config.accentColor : config.secondaryTextColor,
                  fontSize: 12,
                  fontWeight: isMostSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}% ($count)',
              style: TextStyle(
                color: isMostSelected ? config.accentColor : config.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: config.progressBarBackgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              isMostSelected ? config.accentColor : config.progressBarColor.withOpacity(0.6),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

/// Ending history item
class _EndingHistoryItem extends StatelessWidget {
  final EndingRecord record;
  final StatisticsScreenConfig config;

  const _EndingHistoryItem({
    required this.record,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: config.progressBarBackgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: config.accentColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              record.endingName,
              style: TextStyle(
                color: config.textColor,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatDate(record.timestamp),
            style: TextStyle(
              color: config.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
