import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/med_ai_state.dart';
import '../models/medication.dart';
import '../services/med_ai_service.dart';

final medAiServiceProvider = Provider<MedAiService>((ref) {
  return MedAiService();
});

final medAiProvider = StateNotifierProvider<MedAiController, MedAiState>((ref) {
  final service = ref.read(medAiServiceProvider);
  return MedAiController(service);
});

class MedAiController extends StateNotifier<MedAiState> {
  final MedAiService service;

  MedAiController(this.service) : super(MedAiState());

  // builds a string from the med list so we can check if it changed
  // since the last analysis instead of always hitting the API again
  String _signatureFor(List<Medication> meds) {
    final sorted = [...meds]..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map(
          (m) =>
              '${m.id}:${m.name}:${m.dosage}:${m.unit}:${m.frequency}:${m.instructions}',
        )
        .join('|');
  }

  // sends the meds to Groq and updates state with the result.
  // returns true if we used a cached result instead of calling the API
  Future<bool> analyse(List<Medication> meds) async {
    if (meds.isEmpty) {
      state = state.copyWith(
        status: 'error',
        errorMessage: 'Add a medication first to get AI insights.',
      );
      return false;
    }

    final signature = _signatureFor(meds);

    if (state.status == 'success' && state.lastSignature == signature) {
      // nothing changed since last time, don't bother calling the API again
      return true;
    }

    state = state.copyWith(status: 'loading');

    try {
      final result = await service.analyseMeds(meds);

      state = state.copyWith(
        status: 'success',
        interactions: result['interactions'],
        drugInfo: result['drugInfo'],
        lastSignature: signature,
      );
    } catch (e) {
      state = state.copyWith(
        status: 'error',
        errorMessage: 'Could not analyse your medications. Please try again.',
      );
    }

    return false;
  }

  void reset() {
    state = MedAiState();
  }
}
