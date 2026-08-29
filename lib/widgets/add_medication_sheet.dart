import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../models/medication.dart';
import '../providers/firebase_provider.dart';

class AddMedicationSheet extends ConsumerStatefulWidget {
  // pass in an existing med to edit it, otherwise leave null to add new
  final Medication? existing;

  const AddMedicationSheet({this.existing});

  @override
  ConsumerState<AddMedicationSheet> createState() =>
      _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late double _dosage;
  late String _unit;
  late String _frequency;
  late String _scheduledTime;
  late TextEditingController _scheduledTimeController;
  late String _instructions;
  late int _stockCount;  // current remaining
  late int _totalCount;  // total / full pack size

  final List<String> _units = ['mg', 'ml', 'mcg', 'g', 'IU', 'pcs'];
  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every 8 hours',
    'As needed',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = m?.name ?? '';
    _dosage = m?.dosage ?? 0;
    _unit = m?.unit ?? 'mg';
    if (_unit == 'tab' || _unit == 'tabs') {
      _unit = 'pcs';
    } else if (!_units.contains(_unit)) {
      _unit = 'mg';
    }
    _frequency = m?.frequency ?? 'Once daily';
    if (!_frequencies.contains(_frequency)) {
      _frequency = 'Once daily';
    }
    _scheduledTime = m?.scheduledTime ?? '';
    _scheduledTimeController = TextEditingController(text: _scheduledTime);
    _instructions = m?.instructions ?? '';
    _stockCount = m?.stockCount ?? 0;
    _totalCount = m?.totalCount ?? 0;
  }

  @override
  void dispose() {
    _scheduledTimeController.dispose();
    super.dispose();
  }

  TimeOfDay _parseScheduledTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return TimeOfDay.now();
    final hourPart = int.tryParse(parts[0].trim());
    final minutePart = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '').trim());
    if (hourPart == null || minutePart == null) return TimeOfDay.now();
    return TimeOfDay(hour: hourPart % 24, minute: minutePart.clamp(0, 59));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickScheduledTime() async {
    final initialTime = _parseScheduledTime(_scheduledTimeController.text);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        _scheduledTime = _formatTimeOfDay(picked);
        _scheduledTimeController.text = _scheduledTime;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final service = ref.read(firebaseServiceProvider);
    final user = service.getCurrentUser();
    if (user == null) return;

    final med = Medication(
      id: widget.existing?.id ?? '',
      name: _name,
      dosage: _dosage,
      unit: _unit,
      frequency: _frequency,
      scheduledTime: _scheduledTime,
      instructions: _instructions,
      stockCount: _stockCount,
      totalCount: _totalCount,
      userEmail: user.email!,
    );

    try {
      if (widget.existing != null) {
        await service.updateMedication(widget.existing!.id, med);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Medication updated!')));
      } else {
        await service.addMedication(med);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Medication added!')));
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inputBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // title + close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit medication' : 'Add medication',
                      style: AppTextStyles.heading2,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.textMedium,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // medication name
                TextFormField(
                  initialValue: _name,
                  decoration: appInputDecoration('Medication name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter medication name.' : null,
                  onSaved: (v) => _name = v!,
                ),
                const SizedBox(height: 14),

                // dosage + unit
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _dosage > 0 ? _dosage.toString() : '',
                        decoration: appInputDecoration('Dosage amount'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter dosage.';
                          final parsed = double.tryParse(v);
                          if (parsed == null) return 'Invalid.';
                          if (parsed < 0) return 'Cannot be negative.';
                          return null;
                        },
                        onSaved: (v) => _dosage = double.parse(v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: appInputDecoration('Unit'),
                      items: _units
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _unit = v);
                        }
                      },
                    ),
                  ),
                ],
                ),
                const SizedBox(height: 14),

                // frequency
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: appInputDecoration('Frequency'),
                  items: _frequencies
                      .map((f) =>
                          DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _frequency = v);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // scheduled time
                TextFormField(
                  controller: _scheduledTimeController,
                  readOnly: true,
                  decoration: appInputDecoration('Scheduled time(s)').copyWith(
                    hintText: 'Select a time',
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                  onTap: _pickScheduledTime,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter scheduled time.' : null,
                  onSaved: (v) => _scheduledTime = v!,
                ),
                const SizedBox(height: 14),

                // instructions
                TextFormField(
                  initialValue: _instructions,
                  decoration: appInputDecoration('Instructions').copyWith(
                    hintText: 'e.g. After breakfast',
                  ),
                  onSaved: (v) => _instructions = v ?? '',
                ),
                const SizedBox(height: 14),

                // stock: current / total, e.g. 16 / 20
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue:
                            _stockCount > 0 ? _stockCount.toString() : '',
                        decoration: appInputDecoration('Current stock'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter current stock.';
                          final parsed = int.tryParse(v);
                          if (parsed == null) return 'Invalid.';
                          if (parsed < 0) return 'Cannot be negative.';
                          if (parsed > 999) return 'Max is 999.';
                          return null;
                        },
                        onSaved: (v) => _stockCount = int.parse(v!),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('/',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMedium)),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue:
                            _totalCount > 0 ? _totalCount.toString() : '',
                        decoration: appInputDecoration('Total stock'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter total stock.';
                          final parsed = int.tryParse(v);
                          if (parsed == null) return 'Invalid.';
                          if (parsed < 0) return 'Cannot be negative.';
                          if (parsed > 999) return 'Max is 999.';
                          return null;
                        },
                        onSaved: (v) => _totalCount = int.parse(v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // save button
                ElevatedButton(
                  onPressed: _save,
                  child: Text(
                      isEditing ? 'Update medication' : 'Save medication'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
