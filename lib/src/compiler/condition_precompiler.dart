import '../models/vn_variable.dart';
import 'vn_story_bundle.dart';

/// 条件表达式预编译器
///
/// 在编译阶段将条件字符串解析为 ConditionToken AST 并序列化为 JSON，
/// 存入 CompiledNode.data['_compiledCondition']。
/// 运行时从 JSON 反序列化后直接评估，避免每帧重新解析。
class ConditionPrecompiler {
  int _precompiledCount = 0;
  int _failedCount = 0;
  final List<String> _warnings = [];

  PrecompileResult precompile(List<CompiledChapter> chapters) {
    _precompiledCount = 0;
    _failedCount = 0;
    _warnings.clear();

    for (final chapter in chapters) {
      for (final entry in chapter.nodes.entries) {
        final node = entry.value;
        if (node.type == 'condition') {
          _precompileConditionNode(node, chapter.id, entry.key);
        } else if (node.type == 'switch') {
          _precompileSwitchNode(node, chapter.id, entry.key);
        }
      }
    }

    return PrecompileResult(
      precompiled: _precompiledCount,
      failed: _failedCount,
      warnings: List.unmodifiable(_warnings),
    );
  }

  void _precompileConditionNode(CompiledNode node, String chapterId, String nodeId) {
    final expression = node.data['expression'] as String?;
    if (expression == null || expression.isEmpty) return;

    final token = ConditionParser.parse(expression);
    if (token != null) {
      node.data['_compiledCondition'] = token.toJson();
      _precompiledCount++;
    } else {
      _failedCount++;
      _warnings.add('Failed to parse condition in $chapterId/$nodeId: "$expression"');
    }
  }

  void _precompileSwitchNode(CompiledNode node, String chapterId, String nodeId) {
    final cases = node.data['cases'] as List<dynamic>?;
    if (cases == null) return;

    for (var i = 0; i < cases.length; i++) {
      final caseMap = cases[i] as Map<String, dynamic>;
      final expression = caseMap['expression'] as String?;
      if (expression == null || expression.isEmpty) continue;

      final token = ConditionParser.parse(expression);
      if (token != null) {
        caseMap['_compiledCondition'] = token.toJson();
        _precompiledCount++;
      } else {
        _failedCount++;
        _warnings.add('Failed to parse switch case $i in $chapterId/$nodeId: "$expression"');
      }
    }
  }

  /// 运行时评估：优先使用预编译 token，回退到字符串解析
  static bool evaluatePrecompiled(
    Map<String, dynamic> nodeData,
    Map<String, dynamic> variables, {
    String? expressionKey = 'expression',
    String? compiledKey = '_compiledCondition',
  }) {
    final evaluator = ConditionEvaluator(variables);

    final compiledJson = nodeData[compiledKey] as Map<String, dynamic>?;
    if (compiledJson != null) {
      final token = ConditionToken.fromJson(compiledJson);
      return evaluator.evaluate(token) == true;
    }

    final expression = nodeData[expressionKey] as String?;
    if (expression == null || expression.isEmpty) return false;
    return evaluator.evaluateExpression(expression);
  }
}

class PrecompileResult {
  final int precompiled;
  final int failed;
  final List<String> warnings;

  const PrecompileResult({
    required this.precompiled,
    required this.failed,
    required this.warnings,
  });
}
