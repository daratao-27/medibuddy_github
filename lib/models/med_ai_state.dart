import 'ai_insight.dart';

// state for the AI medication analysis screen
class MedAiState {
  final String status; // idle, loading, success, error
  final List<MedInteraction> interactions;
  final List<DrugInfo> drugInfo;
  final String? errorMessage;
  final String? lastSignature; // used to check if the med list changed

  MedAiState({
    this.status = 'idle',
    this.interactions = const [],
    this.drugInfo = const [],
    this.errorMessage,
    this.lastSignature,
  });

  MedAiState copyWith({
    String? status,
    List<MedInteraction>? interactions,
    List<DrugInfo>? drugInfo,
    String? errorMessage,
    String? lastSignature,
  }) {
    return MedAiState(
      status: status ?? this.status,
      interactions: interactions ?? this.interactions,
      drugInfo: drugInfo ?? this.drugInfo,
      errorMessage: errorMessage,
      lastSignature: lastSignature ?? this.lastSignature,
    );
  }
}
