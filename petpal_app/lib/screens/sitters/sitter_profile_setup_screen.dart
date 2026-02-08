import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../models/app_user.dart';
import '../../utils/app_validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';

class SitterProfileSetupScreen extends StatefulWidget {
  const SitterProfileSetupScreen({super.key});

  static const routeName = '/sitter/setup';

  @override
  State<SitterProfileSetupScreen> createState() =>
      _SitterProfileSetupScreenState();
}

class _SitterProfileSetupScreenState extends State<SitterProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Professional Info
  final _experienceDescController = TextEditingController();
  final _yearsExpController = TextEditingController();

  // Lists
  final List<String> _petTypes = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];
  final List<String> _selectedPetTypes = [];

  final List<String> _services = [
    'Day Care',
    'Overnight Sitting',
    'Home Visit',
    'Boarding',
  ];
  final List<String> _selectedServices = [];

  // Availability
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

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _experienceDescController.dispose();
    _yearsExpController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPetTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one pet type')),
      );
      return;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one available day')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please login again.')),
      );
      return;
    }

    final updatedUser = authState.user!.copyWith(
      experience: _experienceDescController.text.trim(),
      yearsOfExperience: int.tryParse(_yearsExpController.text.trim()),
      petTypesAccepted: _selectedPetTypes,
      servicesProvided: _selectedServices,
      availableDays: _selectedDays,
      availableHours: {
        'start': _startTime != null ? _formatTime(_startTime!) : '09:00',
        'end': _endTime != null ? _formatTime(_endTime!) : '17:00',
      },
    );

    // Save to Firestore via Bloc
    context.read<ProfileBloc>().add(ProfileUpdated(updatedUser));

    // Navigate to Dashboard
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  void _toggleListItem(List<String> list, String item) {
    setState(() {
      if (list.contains(item)) {
        list.remove(item);
      } else {
        list.add(item);
      }
    });
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sitter Profile Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete your profile with professional details.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Professional Information'),
              AppTextField(
                controller: _experienceDescController,
                label: 'Experience Description',
                maxLines: 3,
                validator: (v) =>
                    AppValidators.required(v, fieldName: 'Experience'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _yearsExpController,
                label: 'Years of Experience',
                keyboardType: TextInputType.number,
                validator: (v) => AppValidators.required(v, fieldName: 'Years'),
              ),
              const SizedBox(height: 16),

              const Text(
                'Pet Types Accepted',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: _petTypes
                    .map(
                      (type) => FilterChip(
                        label: Text(type),
                        selected: _selectedPetTypes.contains(type),
                        onSelected: (_) =>
                            _toggleListItem(_selectedPetTypes, type),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              const Text(
                'Services Provided',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: _services
                    .map(
                      (s) => FilterChip(
                        label: Text(s),
                        selected: _selectedServices.contains(s),
                        onSelected: (_) =>
                            _toggleListItem(_selectedServices, s),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Availability'),
              Wrap(
                spacing: 8,
                children: _daysOfWeek
                    .map(
                      (d) => FilterChip(
                        label: Text(d),
                        selected: _selectedDays.contains(d),
                        onSelected: (_) => _toggleListItem(_selectedDays, d),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // ... (Time pickers stay same)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(true),
                      child: Text(_startTime?.format(context) ?? 'Start Time'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(false),
                      child: Text(_endTime?.format(context) ?? 'End Time'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              PrimaryButton(label: 'Complete Registration', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
