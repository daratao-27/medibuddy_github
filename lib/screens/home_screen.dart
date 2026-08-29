import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../models/medication.dart';
import '../providers/firebase_provider.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends ConsumerWidget {
  // switches to the Meds tab, passed down from MainScreen
  final VoidCallback onGoToMeds;

  const HomeScreen({required this.onGoToMeds});

  // parses something like "8:00 AM" into a real DateTime for today
  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String period =
          parts.length > 1 ? parts[1].toUpperCase() : 'AM';
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  // finds the next med that hasn't been taken yet.
  // if everything today is done, just shows the earliest one for tomorrow
  Medication? _findNextMed(List<Medication> meds) {
    if (meds.isEmpty) return null;
    final now = DateTime.now();
    Medication? nextMed;
    Duration? shortest;

    for (final med in meds) {
      final medTime = _parseTime(med.scheduledTime);
      if (medTime == null) continue;
      var diff = medTime.difference(now);
      // already passed today, so count it for tomorrow instead
      if (diff.isNegative) diff += const Duration(hours: 24);
      if (shortest == null || diff < shortest) {
        shortest = diff;
        nextMed = med;
      }
    }
    return nextMed;
  }

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month];
  }
  // Build

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    final service = ref.read(firebaseServiceProvider);
    final user = service.getCurrentUser();

    final displayName = user?.displayName ?? user?.email ?? 'there';
    final firstName = displayName.contains(' ')
        ? displayName.split(' ').first
        : displayName.split('@').first;

    final hour = DateTime.now().hour;
    final String greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // top bar: hamburger menu + logo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu,
                            color: AppColors.textDark),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Medi',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          TextSpan(
                            text: 'Buddy',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    const Text('☀️ ', style: TextStyle(fontSize: 22)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $firstName!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Text("Here's your plan for today.",
                            style: AppTextStyles.subtitle),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // next med card, pulled from firestore
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: medsAsync.when(
                  data: (meds) {
                    final scheduledMeds = meds.where((m) => m.scheduledTime.isNotEmpty).toList();
                    final next = _findNextMed(scheduledMeds);
                    return _NextMedCard(
                      time: next?.scheduledTime ?? '—',
                      medCount: scheduledMeds.length,
                      onViewDetails: onGoToMeds,
                    );
                  },
                  loading: () => _NextMedCard(
                      time: '...', medCount: 0, onViewDetails: onGoToMeds),
                  error: (_, __) => _NextMedCard(
                      time: '—', medCount: 0, onViewDetails: onGoToMeds),
                ),
              ),
            ),
            // today's schedule heading
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's schedule",
                        style: AppTextStyles.heading2),
                    Text(
                      '${_monthName(DateTime.now().month)} ${DateTime.now().day}',
                      style: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            // the actual schedule rows, sorted by time
            medsAsync.when(
              data: (meds) {
                if (meds.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No medications added yet.\nGo to Meds to add your first one!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                      ),
                    ),
                  );
                }
                // sort so the earliest time shows first
                final sorted = List<Medication>.from(meds)
                  ..sort((a, b) {
                    final ta = _parseTime(a.scheduledTime) ?? DateTime(0);
                    final tb = _parseTime(b.scheduledTime) ?? DateTime(0);
                    return ta.compareTo(tb);
                  });
                final scheduled = sorted.where((m) => m.scheduledTime.isNotEmpty).toList();
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ScheduleRow(
                      med: scheduled[i],
                      index: i,
                    ),
                    childCount: scheduled.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e')),
              ),
            ),
            // low stock reminder banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: medsAsync.when(
                  data: (meds) {
                    final lowCount = meds.where((m) => m.isLowStock).length;
                    return _RefillBanner(
                      lowCount: lowCount,
                      onView: onGoToMeds,
                    );
                  },
                  loading: () =>
                      _RefillBanner(lowCount: 0, onView: onGoToMeds),
                  error: (_, __) =>
                      _RefillBanner(lowCount: 0, onView: onGoToMeds),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}
// hero card showing the next medication to take
class _NextMedCard extends StatelessWidget {
  final String time;
  final int medCount;
  final VoidCallback onViewDetails;

  const _NextMedCard({
    required this.time,
    required this.medCount,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.nextMedCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications,
                        color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Next medication',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '$medCount medication${medCount == 1 ? '' : 's'}',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 10),
                // takes you to the meds tab
                ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(140, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Details'),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('images/pills.png',
                width: 60, height: 60, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
// one row in today's schedule list
class _ScheduleRow extends StatelessWidget {
  final Medication med;
  final int index;

  const _ScheduleRow({required this.med, required this.index});

  // just rotates through pill images so the list isn't all the same icon
  static const _images = [
    'images/capsule.png',
    'images/pill.png',
    'images/tablet.png',
    'images/pill2.png',
    'images/medicine.png',
    'images/pills.png',
    'images/pill3.png',
    'images/pills2.png',
  ];

  @override
  Widget build(BuildContext context) {
    // check if this dose's time has already passed today
    DateTime? medTime;
    try {
      final parts = med.scheduledTime.trim().split(' ');
      final tp = parts[0].split(':');
      int h = int.parse(tp[0]);
      final int m = int.parse(tp[1]);
      final p = parts.length > 1 ? parts[1].toUpperCase() : 'AM';
      if (p == 'PM' && h != 12) h += 12;
      if (p == 'AM' && h == 12) h = 0;
      final now = DateTime.now();
      medTime = DateTime(now.year, now.month, now.day, h, m);
    } catch (_) {}

    final bool isPast =
        medTime != null && medTime.isBefore(DateTime.now());
    final Color badgeColor =
        isPast ? AppColors.takenBadge : AppColors.soonBadge;
    final String badgeText = isPast ? 'Taken' : 'Soon';
    final IconData badgeIcon =
        isPast ? Icons.check_circle : Icons.access_time;

    final String imgPath = _images[index % _images.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(imgPath,
                  width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.nextMedCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      med.scheduledTime,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(med.name, style: AppTextStyles.bodyBold),
                  Text(
                    '${med.dosage % 1 == 0 ? med.dosage.toInt() : med.dosage}'
                    '${med.unit} · ${med.instructions}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, color: badgeColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
// banner that nudges the user to refill low-stock meds
class _RefillBanner extends StatelessWidget {
  final int lowCount;
  final VoidCallback onView;

  const _RefillBanner({required this.lowCount, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('images/pill-box.png',
                width: 44, height: 44, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Refill reminder',
                    style: AppTextStyles.bodyBold),
                Text(
                  lowCount == 0
                      ? 'All medications well stocked'
                      : '$lowCount medication${lowCount == 1 ? '' : 's'} running low',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (lowCount > 0)
            TextButton(
              onPressed: onView,
              child: const Text('View',
                  style: TextStyle(color: AppColors.textMedium)),
            ),
        ],
      ),
    );
  }
}
