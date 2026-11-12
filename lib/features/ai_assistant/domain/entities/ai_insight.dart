import 'package:equatable/equatable.dart';

class AiInsight extends Equatable {
  final String title;
  final String message;
  final String type; // 'positive', 'suggestion', 'warning', 'info'

  const AiInsight({
    required this.title,
    required this.message,
    required this.type,
  });

  factory AiInsight.fromJson(Map<String, dynamic> json) {
    return AiInsight(
      title: json['title'] as String,
      message: json['message'] as String,
      type: (json['type'] ?? 'info') as String,
    );
  }

  @override
  List<Object?> get props => [title, message, type];
}

class AiAnalysisResult extends Equatable {
  final bool consentRequired;
  final List<AiInsight> insights;
  final String disclaimer;

  const AiAnalysisResult({
    required this.consentRequired,
    required this.insights,
    this.disclaimer =
        'AI-generated recommendations are informational suggestions and do not replace professional financial advice.',
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    final list = (json['insights'] as List<dynamic>? ?? [])
        .map((i) => AiInsight.fromJson(i as Map<String, dynamic>))
        .toList();

    return AiAnalysisResult(
      consentRequired: json['consentRequired'] == true,
      insights: list,
      disclaimer: (json['disclaimer'] ?? '') as String,
    );
  }

  @override
  List<Object?> get props => [consentRequired, insights, disclaimer];
}
