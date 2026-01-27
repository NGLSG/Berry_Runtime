/// Debug Log Exporter for VN Runtime
/// 
/// Provides debug log export capabilities:
/// - State change logging with timestamps
/// - Multiple export formats (JSON, CSV, Markdown)
/// - Filtered exports by event type
/// - Session-based log management

import 'dart:convert';

import 'debug_event.dart';
import 'branch_coverage_analyzer.dart';
import '../vn_engine_state.dart';

/// Export format for debug logs
enum DebugLogFormat {
  /// JSON format (machine-readable)
  json,
  
  /// CSV format (spreadsheet-compatible)
  csv,
  
  /// Markdown format (human-readable)
  markdown,
  
  /// Plain text format
  text,
}

/// Filter options for log export
class DebugLogFilter {
  /// Event types to include (empty = all)
  final Set<Type> eventTypes;
  
  /// Start time filter
  final DateTime? startTime;
  
  /// End time filter
  final DateTime? endTime;
  
  /// Node IDs to filter by
  final Set<String>? nodeIds;
  
  /// Chapter IDs to filter by
  final Set<String>? chapterIds;
  
  /// Variable names to filter by
  final Set<String>? variableNames;

  const DebugLogFilter({
    this.eventTypes = const {},
    this.startTime,
    this.endTime,
    this.nodeIds,
    this.chapterIds,
    this.variableNames,
  });

  /// Check if an event passes the filter
  bool passes(VNDebugEvent event) {
    // Type filter
    if (eventTypes.isNotEmpty && !eventTypes.contains(event.runtimeType)) {
      return false;
    }
    
    // Time filter
    if (startTime != null && event.timestamp.isBefore(startTime!)) {
      return false;
    }
    if (endTime != null && event.timestamp.isAfter(endTime!)) {
      return false;
    }
    
    // Node filter
    if (nodeIds != null && nodeIds!.isNotEmpty) {
      String? eventNodeId;
      if (event is NodeEnterEvent) eventNodeId = event.nodeId;
      if (event is NodeExitEvent) eventNodeId = event.nodeId;
      if (event is ChoiceSelectedEvent) eventNodeId = event.nodeId;
      if (event is ConditionEvaluatedEvent) eventNodeId = event.nodeId;
      if (event is BreakpointHitEvent) eventNodeId = event.nodeId;
      if (event is DialogueAdvanceEvent) eventNodeId = event.nodeId;
      
      if (eventNodeId != null && !nodeIds!.contains(eventNodeId)) {
        return false;
      }
    }
    
    // Chapter filter
    if (chapterIds != null && chapterIds!.isNotEmpty) {
      String? eventChapterId;
      if (event is NodeEnterEvent) eventChapterId = event.chapterId;
      if (event is NodeExitEvent) eventChapterId = event.chapterId;
      if (event is BreakpointHitEvent) eventChapterId = event.chapterId;
      if (event is ChapterChangeEvent) eventChapterId = event.newChapterId;
      
      if (eventChapterId != null && !chapterIds!.contains(eventChapterId)) {
        return false;
      }
    }
    
    // Variable filter
    if (variableNames != null && variableNames!.isNotEmpty) {
      if (event is VariableChangeEvent) {
        if (!variableNames!.contains(event.variableName)) {
          return false;
        }
      }
    }
    
    return true;
  }
}

/// Debug session information
class DebugSession {
  /// Session ID
  final String id;
  
  /// Session start time
  final DateTime startTime;
  
  /// Session end time
  DateTime? endTime;
  
  /// Project name
  final String? projectName;
  
  /// Chapter being debugged
  final String? chapterId;
  
  /// Events in this session
  final List<VNDebugEvent> events = [];
  
  /// Session notes
  String? notes;

  DebugSession({
    required this.id,
    required this.startTime,
    this.projectName,
    this.chapterId,
  });

  /// Duration of the session
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  /// Add an event to the session
  void addEvent(VNDebugEvent event) {
    events.add(event);
  }

  /// End the session
  void end() {
    endTime = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toIso8601String(),
    'durationMs': duration.inMilliseconds,
    if (projectName != null) 'projectName': projectName,
    if (chapterId != null) 'chapterId': chapterId,
    if (notes != null) 'notes': notes,
    'eventCount': events.length,
    'events': events.map((e) => e.toJson()).toList(),
  };
}

/// Debug log exporter
class DebugLogExporter {
  /// Export events to JSON format
  static String exportToJson(
    List<VNDebugEvent> events, {
    DebugLogFilter? filter,
    bool prettyPrint = true,
    Map<String, dynamic>? metadata,
  }) {
    final filteredEvents = filter != null
        ? events.where(filter.passes).toList()
        : events;

    final data = {
      'exportTime': DateTime.now().toIso8601String(),
      'eventCount': filteredEvents.length,
      if (metadata != null) 'metadata': metadata,
      'events': filteredEvents.map((e) => e.toJson()).toList(),
    };

    if (prettyPrint) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return jsonEncode(data);
  }

  /// Export events to CSV format
  static String exportToCsv(
    List<VNDebugEvent> events, {
    DebugLogFilter? filter,
  }) {
    final filteredEvents = filter != null
        ? events.where(filter.passes).toList()
        : events;

    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Timestamp,Type,Details');
    
    // Events
    for (final event in filteredEvents) {
      final timestamp = event.timestamp.toIso8601String();
      final type = event.runtimeType.toString();
      final details = _getEventDetails(event).replaceAll(',', ';').replaceAll('\n', ' ');
      
      buffer.writeln('$timestamp,$type,"$details"');
    }
    
    return buffer.toString();
  }

  /// Export events to Markdown format
  static String exportToMarkdown(
    List<VNDebugEvent> events, {
    DebugLogFilter? filter,
    String? title,
    Map<String, dynamic>? metadata,
  }) {
    final filteredEvents = filter != null
        ? events.where(filter.passes).toList()
        : events;

    final buffer = StringBuffer();
    
    // Title
    buffer.writeln('# ${title ?? "Debug Log Export"}');
    buffer.writeln();
    
    // Metadata
    buffer.writeln('**Export Time:** ${DateTime.now().toIso8601String()}');
    buffer.writeln('**Event Count:** ${filteredEvents.length}');
    if (metadata != null) {
      for (final entry in metadata.entries) {
        buffer.writeln('**${entry.key}:** ${entry.value}');
      }
    }
    buffer.writeln();
    
    // Summary
    buffer.writeln('## Summary');
    buffer.writeln();
    final summary = _generateSummary(filteredEvents);
    for (final entry in summary.entries) {
      buffer.writeln('- **${entry.key}:** ${entry.value}');
    }
    buffer.writeln();
    
    // Events
    buffer.writeln('## Events');
    buffer.writeln();
    
    for (final event in filteredEvents) {
      buffer.writeln(_formatEventAsMarkdown(event));
    }
    
    return buffer.toString();
  }

  /// Export events to plain text format
  static String exportToText(
    List<VNDebugEvent> events, {
    DebugLogFilter? filter,
  }) {
    final filteredEvents = filter != null
        ? events.where(filter.passes).toList()
        : events;

    final buffer = StringBuffer();
    
    buffer.writeln('=== Debug Log Export ===');
    buffer.writeln('Export Time: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Event Count: ${filteredEvents.length}');
    buffer.writeln('');
    buffer.writeln('=== Events ===');
    buffer.writeln('');
    
    for (final event in filteredEvents) {
      buffer.writeln(_formatEventAsText(event));
    }
    
    return buffer.toString();
  }

  /// Export to specified format
  static String export(
    List<VNDebugEvent> events,
    DebugLogFormat format, {
    DebugLogFilter? filter,
    String? title,
    Map<String, dynamic>? metadata,
  }) {
    switch (format) {
      case DebugLogFormat.json:
        return exportToJson(events, filter: filter, metadata: metadata);
      case DebugLogFormat.csv:
        return exportToCsv(events, filter: filter);
      case DebugLogFormat.markdown:
        return exportToMarkdown(events, filter: filter, title: title, metadata: metadata);
      case DebugLogFormat.text:
        return exportToText(events, filter: filter);
    }
  }

  /// Export a debug session
  static String exportSession(
    DebugSession session,
    DebugLogFormat format, {
    DebugLogFilter? filter,
  }) {
    final metadata = {
      'sessionId': session.id,
      'startTime': session.startTime.toIso8601String(),
      if (session.endTime != null) 'endTime': session.endTime!.toIso8601String(),
      'duration': '${session.duration.inSeconds}s',
      if (session.projectName != null) 'project': session.projectName,
      if (session.chapterId != null) 'chapter': session.chapterId,
      if (session.notes != null) 'notes': session.notes,
    };

    return export(
      session.events,
      format,
      filter: filter,
      title: 'Debug Session: ${session.id}',
      metadata: metadata,
    );
  }

  /// Export coverage report
  static String exportCoverageReport(
    CoverageReport report,
    DebugLogFormat format,
  ) {
    switch (format) {
      case DebugLogFormat.json:
        return const JsonEncoder.withIndent('  ').convert(report.toJson());
      case DebugLogFormat.markdown:
        return _formatCoverageAsMarkdown(report);
      default:
        return _formatCoverageAsText(report);
    }
  }

  // ==================== Private Helpers ====================

  static String _getEventDetails(VNDebugEvent event) {
    if (event is NodeEnterEvent) {
      return 'Enter ${event.nodeType} node: ${event.nodeId} in ${event.chapterId}';
    }
    if (event is NodeExitEvent) {
      return 'Exit node: ${event.nodeId}${event.nextNodeId != null ? ' -> ${event.nextNodeId}' : ''}';
    }
    if (event is VariableChangeEvent) {
      return '${event.variableName}: ${event.previousValue} -> ${event.newValue}';
    }
    if (event is ChoiceSelectedEvent) {
      return 'Choice ${event.optionIndex}: ${event.optionText}';
    }
    if (event is ConditionEvaluatedEvent) {
      return '${event.expression} = ${event.result}';
    }
    if (event is StateChangeEvent) {
      return '${event.previousState.name} -> ${event.newState.name}';
    }
    if (event is DialogueAdvanceEvent) {
      return '${event.speakerId ?? "Narrator"}: ${event.text}';
    }
    if (event is ErrorEvent) {
      return 'Error: ${event.message}';
    }
    if (event is BreakpointHitEvent) {
      return 'Breakpoint at ${event.nodeId}';
    }
    if (event is ChapterChangeEvent) {
      return 'Chapter: ${event.previousChapterId ?? "start"} -> ${event.newChapterId}';
    }
    return event.runtimeType.toString();
  }

  static Map<String, int> _generateSummary(List<VNDebugEvent> events) {
    final summary = <String, int>{};
    
    for (final event in events) {
      final type = event.runtimeType.toString();
      summary[type] = (summary[type] ?? 0) + 1;
    }
    
    return summary;
  }

  static String _formatEventAsMarkdown(VNDebugEvent event) {
    final time = '${event.timestamp.hour.toString().padLeft(2, '0')}:'
        '${event.timestamp.minute.toString().padLeft(2, '0')}:'
        '${event.timestamp.second.toString().padLeft(2, '0')}.'
        '${event.timestamp.millisecond.toString().padLeft(3, '0')}';
    
    final icon = _getEventIcon(event);
    final details = _getEventDetails(event);
    
    return '- `$time` $icon **${event.runtimeType}**: $details';
  }

  static String _formatEventAsText(VNDebugEvent event) {
    final time = '${event.timestamp.hour.toString().padLeft(2, '0')}:'
        '${event.timestamp.minute.toString().padLeft(2, '0')}:'
        '${event.timestamp.second.toString().padLeft(2, '0')}.'
        '${event.timestamp.millisecond.toString().padLeft(3, '0')}';
    
    final details = _getEventDetails(event);
    
    return '[$time] ${event.runtimeType}: $details';
  }

  static String _getEventIcon(VNDebugEvent event) {
    if (event is NodeEnterEvent) return '➡️';
    if (event is NodeExitEvent) return '⬅️';
    if (event is VariableChangeEvent) return '📝';
    if (event is ChoiceSelectedEvent) return '🔘';
    if (event is ConditionEvaluatedEvent) return '❓';
    if (event is StateChangeEvent) return '🔄';
    if (event is DialogueAdvanceEvent) return '💬';
    if (event is ErrorEvent) return '❌';
    if (event is BreakpointHitEvent) return '🔴';
    if (event is ChapterChangeEvent) return '📖';
    return '📌';
  }

  static String _formatCoverageAsMarkdown(CoverageReport report) {
    final buffer = StringBuffer();
    
    buffer.writeln('# Coverage Report');
    buffer.writeln();
    buffer.writeln('**Generated:** ${report.timestamp.toIso8601String()}');
    buffer.writeln();
    
    buffer.writeln('## Overall Coverage');
    buffer.writeln();
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Node Coverage | ${(report.nodeCoverage * 100).toStringAsFixed(1)}% |');
    buffer.writeln('| Edge Coverage | ${(report.edgeCoverage * 100).toStringAsFixed(1)}% |');
    buffer.writeln('| Overall | ${(report.overallCoverage * 100).toStringAsFixed(1)}% |');
    buffer.writeln('| Visited Nodes | ${report.visitedNodes}/${report.totalNodes} |');
    buffer.writeln('| Traversed Edges | ${report.traversedEdges}/${report.totalEdges} |');
    buffer.writeln();
    
    buffer.writeln('## Chapter Details');
    buffer.writeln();
    
    for (final chapter in report.chapterReports) {
      buffer.writeln('### ${chapter.chapterTitle}');
      buffer.writeln();
      buffer.writeln('- Node Coverage: ${(chapter.nodeCoverage * 100).toStringAsFixed(1)}%');
      buffer.writeln('- Edge Coverage: ${(chapter.edgeCoverage * 100).toStringAsFixed(1)}%');
      buffer.writeln('- Choice Coverage: ${(chapter.choiceCoverage * 100).toStringAsFixed(1)}%');
      
      if (chapter.untestedNodes.isNotEmpty) {
        buffer.writeln('- Untested Nodes: ${chapter.untestedNodes.join(", ")}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  static String _formatCoverageAsText(CoverageReport report) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== Coverage Report ===');
    buffer.writeln('Generated: ${report.timestamp.toIso8601String()}');
    buffer.writeln();
    buffer.writeln('Overall Coverage:');
    buffer.writeln('  Node Coverage: ${(report.nodeCoverage * 100).toStringAsFixed(1)}%');
    buffer.writeln('  Edge Coverage: ${(report.edgeCoverage * 100).toStringAsFixed(1)}%');
    buffer.writeln('  Overall: ${(report.overallCoverage * 100).toStringAsFixed(1)}%');
    buffer.writeln();
    
    for (final chapter in report.chapterReports) {
      buffer.writeln('Chapter: ${chapter.chapterTitle}');
      buffer.writeln('  Nodes: ${chapter.visitedNodes}/${chapter.totalNodes}');
      buffer.writeln('  Edges: ${chapter.traversedEdges}/${chapter.totalEdges}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}


/// Debug session manager
/// 
/// Manages debug sessions and provides session-based logging.
class DebugSessionManager {
  /// Active sessions
  final Map<String, DebugSession> _sessions = {};
  
  /// Current active session
  DebugSession? _currentSession;
  
  /// Session history (completed sessions)
  final List<DebugSession> _sessionHistory = [];
  
  /// Maximum history size
  final int maxHistorySize;

  DebugSessionManager({this.maxHistorySize = 10});

  /// Get current session
  DebugSession? get currentSession => _currentSession;
  
  /// Get all active sessions
  List<DebugSession> get activeSessions => _sessions.values.toList();
  
  /// Get session history
  List<DebugSession> get sessionHistory => List.unmodifiable(_sessionHistory);

  /// Start a new debug session
  DebugSession startSession({
    String? projectName,
    String? chapterId,
  }) {
    final session = DebugSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now(),
      projectName: projectName,
      chapterId: chapterId,
    );
    
    _sessions[session.id] = session;
    _currentSession = session;
    
    return session;
  }

  /// End a session
  void endSession(String sessionId) {
    final session = _sessions.remove(sessionId);
    if (session != null) {
      session.end();
      _sessionHistory.add(session);
      
      // Trim history if needed
      while (_sessionHistory.length > maxHistorySize) {
        _sessionHistory.removeAt(0);
      }
      
      if (_currentSession?.id == sessionId) {
        _currentSession = _sessions.values.isNotEmpty 
            ? _sessions.values.last 
            : null;
      }
    }
  }

  /// End current session
  void endCurrentSession() {
    if (_currentSession != null) {
      endSession(_currentSession!.id);
    }
  }

  /// Add event to current session
  void addEvent(VNDebugEvent event) {
    _currentSession?.addEvent(event);
  }

  /// Add note to current session
  void addNote(String note) {
    if (_currentSession != null) {
      _currentSession!.notes = (_currentSession!.notes ?? '') + '\n$note';
    }
  }

  /// Get session by ID
  DebugSession? getSession(String sessionId) {
    return _sessions[sessionId] ?? 
        _sessionHistory.where((s) => s.id == sessionId).firstOrNull;
  }

  /// Export current session
  String? exportCurrentSession(DebugLogFormat format, {DebugLogFilter? filter}) {
    if (_currentSession == null) return null;
    return DebugLogExporter.exportSession(_currentSession!, format, filter: filter);
  }

  /// Export session by ID
  String? exportSession(String sessionId, DebugLogFormat format, {DebugLogFilter? filter}) {
    final session = getSession(sessionId);
    if (session == null) return null;
    return DebugLogExporter.exportSession(session, format, filter: filter);
  }

  /// Clear all sessions
  void clearAll() {
    for (final session in _sessions.values) {
      session.end();
    }
    _sessions.clear();
    _sessionHistory.clear();
    _currentSession = null;
  }

  /// Get combined events from all active sessions
  List<VNDebugEvent> getAllActiveEvents() {
    final events = <VNDebugEvent>[];
    for (final session in _sessions.values) {
      events.addAll(session.events);
    }
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return events;
  }
}

/// State change logger
/// 
/// Specialized logger for tracking state changes with detailed context.
class StateChangeLogger {
  /// State change history
  final List<StateChangeRecord> _history = [];
  
  /// Maximum history size
  final int maxHistorySize;

  StateChangeLogger({this.maxHistorySize = 500});

  /// Get state change history
  List<StateChangeRecord> get history => List.unmodifiable(_history);

  /// Log a state change
  void logStateChange({
    required String category,
    required String description,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? newState,
    String? nodeId,
    String? chapterId,
    Map<String, dynamic>? additionalData,
  }) {
    final record = StateChangeRecord(
      timestamp: DateTime.now(),
      category: category,
      description: description,
      previousState: previousState,
      newState: newState,
      nodeId: nodeId,
      chapterId: chapterId,
      additionalData: additionalData,
    );
    
    _history.add(record);
    
    // Trim history if needed
    while (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
  }

  /// Log variable change
  void logVariableChange(
    String name,
    dynamic previousValue,
    dynamic newValue, {
    String? nodeId,
    String? chapterId,
  }) {
    logStateChange(
      category: 'variable',
      description: '$name: $previousValue -> $newValue',
      previousState: {'value': previousValue},
      newState: {'value': newValue},
      nodeId: nodeId,
      chapterId: chapterId,
      additionalData: {'variableName': name},
    );
  }

  /// Log position change
  void logPositionChange(
    String? previousNodeId,
    String newNodeId, {
    String? previousChapterId,
    String? newChapterId,
  }) {
    logStateChange(
      category: 'position',
      description: '${previousNodeId ?? "start"} -> $newNodeId',
      previousState: {
        'nodeId': previousNodeId,
        'chapterId': previousChapterId,
      },
      newState: {
        'nodeId': newNodeId,
        'chapterId': newChapterId,
      },
      nodeId: newNodeId,
      chapterId: newChapterId,
    );
  }

  /// Log playback state change
  void logPlaybackStateChange(
    VNPlaybackState previousState,
    VNPlaybackState newState, {
    String? reason,
    String? nodeId,
    String? chapterId,
  }) {
    logStateChange(
      category: 'playback',
      description: '${previousState.name} -> ${newState.name}',
      previousState: {'state': previousState.name},
      newState: {'state': newState.name},
      nodeId: nodeId,
      chapterId: chapterId,
      additionalData: reason != null ? {'reason': reason} : null,
    );
  }

  /// Get changes by category
  List<StateChangeRecord> getByCategory(String category) {
    return _history.where((r) => r.category == category).toList();
  }

  /// Get changes in time range
  List<StateChangeRecord> getInTimeRange(DateTime start, DateTime end) {
    return _history.where((r) => 
      r.timestamp.isAfter(start) && r.timestamp.isBefore(end)
    ).toList();
  }

  /// Export history
  String export(DebugLogFormat format) {
    switch (format) {
      case DebugLogFormat.json:
        return const JsonEncoder.withIndent('  ').convert({
          'exportTime': DateTime.now().toIso8601String(),
          'recordCount': _history.length,
          'records': _history.map((r) => r.toJson()).toList(),
        });
      case DebugLogFormat.csv:
        final buffer = StringBuffer();
        buffer.writeln('Timestamp,Category,Description,NodeId,ChapterId');
        for (final record in _history) {
          buffer.writeln(
            '${record.timestamp.toIso8601String()},'
            '${record.category},'
            '"${record.description}",'
            '${record.nodeId ?? ""},'
            '${record.chapterId ?? ""}'
          );
        }
        return buffer.toString();
      default:
        final buffer = StringBuffer();
        for (final record in _history) {
          buffer.writeln(record.toString());
        }
        return buffer.toString();
    }
  }

  /// Clear history
  void clear() {
    _history.clear();
  }
}

/// A single state change record
class StateChangeRecord {
  /// Timestamp
  final DateTime timestamp;
  
  /// Category (variable, position, playback, etc.)
  final String category;
  
  /// Human-readable description
  final String description;
  
  /// Previous state data
  final Map<String, dynamic>? previousState;
  
  /// New state data
  final Map<String, dynamic>? newState;
  
  /// Related node ID
  final String? nodeId;
  
  /// Related chapter ID
  final String? chapterId;
  
  /// Additional context data
  final Map<String, dynamic>? additionalData;

  const StateChangeRecord({
    required this.timestamp,
    required this.category,
    required this.description,
    this.previousState,
    this.newState,
    this.nodeId,
    this.chapterId,
    this.additionalData,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'category': category,
    'description': description,
    if (previousState != null) 'previousState': previousState,
    if (newState != null) 'newState': newState,
    if (nodeId != null) 'nodeId': nodeId,
    if (chapterId != null) 'chapterId': chapterId,
    if (additionalData != null) 'additionalData': additionalData,
  };

  @override
  String toString() {
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '[$time] [$category] $description';
  }
}
