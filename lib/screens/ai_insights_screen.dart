import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../providers/firebase_provider.dart';
import '../providers/med_ai_provider.dart';

class AiInsightsScreen extends ConsumerWidget {
  const AiInsightsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    final aiState = ref.watch(medAiProvider);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // heading
              Row(
                children: [
                  Image.asset('images/ai.png', width: 32, height: 32),
                  const SizedBox(width: 8),
                  const Text('AI Insights', style: AppTextStyles.heading1),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Get AI-powered analysis of your medications for\n'
                'interactions, timing, and more.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 24),
              // the "your medications" card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // header row
                    medsAsync.when(
                      data: (meds) => Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Medications (${meds.length})',
                            style: AppTextStyles.bodyBold,
                          ),
                        ],
                      ),
                      loading: () => Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Your Medications',
                            style: AppTextStyles.bodyBold,
                          ),
                        ],
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),

                    // list of meds
                    medsAsync.when(
                      data: (meds) {
                        if (meds.isEmpty) {
                          return Text(
                            'No medications added yet.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textMedium,
                            ),
                          );
                        }
                        return Column(
                          children: meds
                              .map(
                                (m) => _MedBullet(
                                  name: m.name.split(' ').first,
                                  dose:
                                      '${m.dosage % 1 == 0 ? m.dosage.toInt() : m.dosage}${m.unit}',
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    // sends the current med list to Groq
                    ElevatedButton.icon(
                      onPressed: aiState.status == 'loading'
                          ? null
                          : () async {
                              final meds = medsAsync.value ?? [];
                              final usedCache = await ref
                                  .read(medAiProvider.notifier)
                                  .analyse(meds);

                              if (usedCache && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No changes since last analysis — showing cached results.',
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: aiState.status == 'loading'
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Image.asset(
                              'images/idea.png',
                              width: 20,
                              height: 20,
                            ),
                      label: Text(
                        aiState.status == 'loading'
                            ? 'Analysing...'
                            : 'Analyse My Meds',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // error state
              if (aiState.status == 'error')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEAEA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF5B5B5)),
                  ),
                  child: Text(
                    aiState.errorMessage ?? 'Something went wrong.',
                    style: AppTextStyles.body,
                  ),
                ),

              // nothing analysed yet
              if (aiState.status == 'idle')
                Text(
                  "Tap 'Analyse My Meds' above to get AI-powered insights "
                  'on interactions and what each medication does.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),

              // only show results once we actually have them
              if (aiState.status == 'success') ...[
                // interactions section
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Potential Interactions',
                      style: AppTextStyles.heading2,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (aiState.interactions.isEmpty)
                  Text(
                    'No notable interactions found between your current medications.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMedium,
                    ),
                  )
                else
                  ...aiState.interactions.map(
                    (item) =>
                        _InteractionCard(title: item.title, body: item.body),
                  ),

                const SizedBox(height: 28),
                // what each drug does section
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('What Each Does', style: AppTextStyles.heading2),
                  ],
                ),
                const SizedBox(height: 12),

                ...aiState.drugInfo.map(
                  (item) => _DrugInfoCard(
                    name: item.name,
                    description: item.description,
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// small helper widgets below

// orange bullet + name/dose row shown in the "your medications" card
class _MedBullet extends StatelessWidget {
  final String name;
  final String dose;
  const _MedBullet({required this.name, required this.dose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, color: Theme.of(context).colorScheme.primary, size: 10),
          const SizedBox(width: 10),
          Text(name, style: AppTextStyles.bodyBold),
          const SizedBox(width: 6),
          Text(
            dose,
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}

// yellow card for a drug-drug interaction
class _InteractionCard extends StatelessWidget {
  final String title;
  final String body;
  const _InteractionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(body, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// white card describing what a medication does
class _DrugInfoCard extends StatelessWidget {
  final String name;
  final String description;
  const _DrugInfoCard({required this.name, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTextStyles.bodyBold),
          const SizedBox(height: 6),
          Text(description, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
