import 'package:flutter/material.dart';
import '../../utils/app_validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';

class VetProfileSetupScreen extends StatefulWidget {
  const VetProfileSetupScreen({super.key});

  static const routeName = '/vet/setup';

  @override
  State<VetProfileSetupScreen> createState() => _VetProfileSetupScreenState();
}

class _VetProfileSetupScreenState extends State<VetProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _clinicNameController = TextEditingController();
  final _clinicRegNumberController = TextEditingController();
  final _clinicDescriptionController = TextEditingController();
  final _workingHoursStartController = TextEditingController();
  final _workingHoursEndController = TextEditingController();

  // Specializations
  final List<String> _allSpecializations = [
    'General Practice',
    'Surgery',
    'Dermatology',
    'Exotic Animals',
    'Emergency Care',
    'Dentistry',
    'Internal Medicine',
  ];
  final List<String> _selectedSpecializations = [];

  // Working Days
  final List<String> _daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final List<String> _selectedDays = [];

  @override
  void dispose() {
    _clinicNameController.dispose();
    _clinicRegNumberController.dispose();
    _clinicDescriptionController.dispose();
    _workingHoursStartController.dispose();
    _workingHoursEndController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialization'),
        ),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one working day')),
      );
      return;
    }

    // In a real app, we would update the user profile in Firestore here.
    // Since AuthBloc handles the initial registration, we might need a separate event
    // or ProfileBloc to update the "Vet" specific fields.
    // For this prompt, assume we just complete the flow and go to Home.

    // Dispatch an event to update user profile with vet details
    // context.read<AuthBloc>().add(UpdateVetProfile(...));

    // For now, navigate to Home as a placeholder for completion
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  void _toggleSpecialization(String spec) {
    setState(() {
      if (_selectedSpecializations.contains(spec)) {
        _selectedSpecializations.remove(spec);
      } else {
        _selectedSpecializations.add(spec);
      }
    });
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      controller.text = picked.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Profile Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Professional Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _clinicNameController,
                label: 'Clinic Name',
                validator: (v) =>
                    AppValidators.required(v, fieldName: 'Clinic Name'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _clinicRegNumberController,
                label: 'Clinic Registration Number',
                validator: (v) =>
                    AppValidators.required(v, fieldName: 'Reg Number'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _clinicDescriptionController,
                label: 'Clinic Description',
                maxLines: 3,
                validator: (v) =>
                    AppValidators.required(v, fieldName: 'Description'),
              ),

              const SizedBox(height: 24),
              const Text(
                'Specialization',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allSpecializations.map((spec) {
                  final isSelected = _selectedSpecializations.contains(spec);
                  return FilterChip(
                    label: Text(spec),
                    selected: isSelected,
                    onSelected: (_) => _toggleSpecialization(spec),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Text(
                'Working Days',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _daysOfWeek.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) => _toggleDay(day),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(_workingHoursStartController),
                      child: AbsorbPointer(
                        child: AppTextField(
                          controller: _workingHoursStartController,
                          label: 'Start Time',
                          validator: (v) => AppValidators.required(
                            v,
                            fieldName: 'Start Time',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(_workingHoursEndController),
                      child: AbsorbPointer(
                        child: AppTextField(
                          controller: _workingHoursEndController,
                          label: 'End Time',
                          validator: (v) =>
                              AppValidators.required(v, fieldName: 'End Time'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              PrimaryButton(label: 'Complete Setup', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
