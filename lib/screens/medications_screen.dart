import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../models/medication.dart';
import '../providers/firebase_provider.dart';
import '../widgets/add_medication_sheet.dart';
import 'shop_screen.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen();

  // same frequency list as AddMedicationSheet, reused so the filter
  // dropdown only shows values that actually exist
  static const List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every 8 hours',
    'As needed',
  ];

  Future<void> _deleteMedication(
      BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete medication'),
        content:
            const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(firebaseServiceProvider);
        await service.deleteMedication(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication deleted.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _openAddSheet(BuildContext context, {Medication? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    final statsAsync = ref.watch(medStatsProvider);
    final filter = ref.watch(medFilterProvider);
    final sortKey = ref.watch(medSortProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // screen title
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'My ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    TextSpan(
                      text: 'Medications',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // stats row, total meds + low stock count via a firestore count()
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: statsAsync.when(
                data: (stats) => Row(
                  children: [
                    _StatChip(
                        label: '${stats['total']} tracked',
                        color: AppColors.primaryPurple),
                    const SizedBox(width: 8),
                    if ((stats['lowStock'] ?? 0) > 0)
                      _StatChip(
                          label: '${stats['lowStock']} low stock',
                          color: Colors.red),
                  ],
                ),
                loading: () => const SizedBox(
                    height: 24,
                    child: Center(
                        child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2)))),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),

            // filter and sort bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: filter,
                      decoration: const InputDecoration(
                        labelText: 'Filter',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: 'all', child: Text('All')),
                        const DropdownMenuItem(
                            value: 'lowStock', child: Text('Low Stock')),
                        const DropdownMenuItem(
                            value: 'criticalStock', child: Text('Critical Stock (0-5)')),
                        ..._frequencies.map((f) =>
                            DropdownMenuItem(value: f, child: Text(f))),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(medFilterProvider.notifier).state = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: sortKey,
                      decoration: const InputDecoration(
                        labelText: 'Sort by',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'name_asc', child: Text('Name (A-Z)')),
                        DropdownMenuItem(
                            value: 'name_desc', child: Text('Name (Z-A)')),
                        DropdownMenuItem(
                            value: 'stock_asc',
                            child: Text('Stock (Low-High)')),
                        DropdownMenuItem(
                            value: 'stock_desc',
                            child: Text('Stock (High-Low)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(medSortProvider.notifier).state = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // the med list itself
            Expanded(
              child: medsAsync.when(
                data: (meds) {
                  if (meds.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('images/pill-box.png',
                              width: 100, height: 100),
                          const SizedBox(height: 16),
                          Text(
                            filter == 'all'
                                ? 'No medications yet.'
                                : 'No medications match this filter.',
                            style: AppTextStyles.bodyBold,
                          ),
                          const SizedBox(height: 8),
                          const Text('Tap + to add your first medication.',
                              style: AppTextStyles.subtitle),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '${meds.length} medication${meds.length == 1 ? '' : 's'} shown',
                          style: AppTextStyles.subtitle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: meds.length,
                          itemBuilder: (context, i) => _MedicationCard(
                            med: meds[i],
                            index: i,
                            onEdit: () =>
                                _openAddSheet(context, existing: meds[i]),
                            onDelete: () =>
                                _deleteMedication(context, ref, meds[i].id),
                          ),
                        ),
                      ),

                      // reorder/buy button, goes to the shop
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShopScreen(),
                              settings: const RouteSettings(name: ShopScreen.routeName),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            minimumSize:
                                const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Reorder/Buy medication',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error: $e\n\nIf this mentions a missing index, open the '
                      'link inside the error message once to let Firestore '
                      'build it, then try this filter/sort again.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// small pill-shaped badge used in the stats row
class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// card for a single medication
class _MedicationCard extends StatelessWidget {
  final Medication med;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.med,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  // rotate pill images so cards aren't all identical
  static const _images = [
    'images/capsule.png',
    'images/pill.png',
    'images/tablet.png',
    'images/pill2.png',
    'images/medicine.png',
    'images/pills.png',
  ];

  Color _progressColor(double pct) {
    if (pct > 0.5) return AppColors.progressGreen;
    if (pct > 0.25) return AppColors.progressBlue;
    return AppColors.progressYellow;
  }

  @override
  Widget build(BuildContext context) {
    final pct = med.stockPercentage;
    final String imgPath = _images[index % _images.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // pill image, just cycles through the images folder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(imgPath,
                width: 35, height: 35, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: AppTextStyles.bodyBold),
                Text(
                  '${med.dosage % 1 == 0 ? med.dosage.toInt() : med.dosage}'
                  '${med.unit} · ${med.instructions}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),

                // progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.progressTrack,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _progressColor(pct)),
                  ),
                ),
                const SizedBox(height: 4),

                // e.g. "16/20 - 80% left"
                Row(
                  children: [
                    Text(
                      '${med.stockCount}/${med.totalCount} · ${(pct * 100).round()}% left',
                      style: AppTextStyles.caption,
                    ),
                    if (med.isLowStock) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.warning_amber,
                          color: AppColors.lowStockBadge, size: 14),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // edit / delete buttons
          Column(
            children: [
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonDark,
                    minimumSize: const Size(70, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonDark,
                    minimumSize: const Size(70, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
