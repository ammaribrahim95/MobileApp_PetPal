import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../utils/app_validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onSave,
  });

  static const routeName = '/profile/edit';

  final AppUser user;
  final Function(AppUser) onSave;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _birthdayController;

  // Vet Data
  List<String> _selectedSpecializations = [];

  // Shared Availability (Vet & Sitter)
  List<String> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Sitter controllers & Data
  late TextEditingController _experienceController; // Description
  late TextEditingController _pricingController;
  late TextEditingController _yearsExpController;

  String? _selectedState; // For Service Area

  List<String> _selectedPetTypes = [];
  List<String> _selectedServices = [];

  final List<String> _allSpecializations = [
    'General Practice',
    'Surgery',
    'Dermatology',
    'Exotic Animals',
    'Emergency Care',
    'Dentistry',
    'Internal Medicine',
  ];

  final List<String> _daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Sitter Constants
  final List<String> _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Labuan',
    'Putrajaya',
  ];

  final List<String> _petTypes = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];
  final List<String> _sitterServices = [
    'Day Care',
    'Overnight Sitting',
    'Home Visit',
    'Boarding',
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _addressController = TextEditingController(text: user.address);
    _addressController.addListener(() {
      if (mounted) setState(() {});
    });
    _birthdayController = TextEditingController(text: user.birthday);

    if (user.role == UserRole.vet) {
      _initVetData(user);
    } else if (user.role == UserRole.sitter) {
      _initSitterData(user);
    }
  }

  void _initVetData(AppUser user) {
    if (user.specialization != null && user.specialization!.isNotEmpty) {
      _selectedSpecializations = user.specialization!
          .split(',')
          .map((e) => e.trim())
          .toList();
    }

    // Parse Vet Schedule
    if (user.schedule != null && user.schedule!.isNotEmpty) {
      final parts = user.schedule!.split('|');
      if (parts.isNotEmpty) {
        final daysStr = parts[0];
        _selectedDays = daysStr.split(',').map((e) => e.trim()).toList();

        if (parts.length > 1) {
          final timePart = parts[1].trim();
          final times = timePart.split('-');
          if (times.length == 2) {
            _startTime = _parseTime(times[0].trim());
            _endTime = _parseTime(times[1].trim());
          }
        }
      }
    }
  }

  void _initSitterData(AppUser user) {
    _experienceController = TextEditingController(text: user.experience);
    _pricingController = TextEditingController(text: user.pricing?.toString());
    _yearsExpController = TextEditingController(
      text: user.yearsOfExperience?.toString(),
    );

    _selectedState = user.serviceArea; // Assuming serviceArea stores state name

    if (user.petTypesAccepted != null) {
      _selectedPetTypes = List.from(user.petTypesAccepted!);
    }
    if (user.servicesProvided != null) {
      _selectedServices = List.from(user.servicesProvided!);
    }
    if (user.availableDays != null) {
      _selectedDays = List.from(user.availableDays!);
    }

    if (user.availableHours != null) {
      if (user.availableHours!.containsKey('start')) {
        _startTime = _parseTime(user.availableHours!['start']!);
      }
      if (user.availableHours!.containsKey('end')) {
        _endTime = _parseTime(user.availableHours!['end']!);
      }
    }
  }

  TimeOfDay? _parseTime(String s) {
    try {
      final parts = s.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1].split(' ')[0]);

        if (s.toLowerCase().contains('pm') && hour < 12) hour += 12;
        if (s.toLowerCase().contains('am') && hour == 12) hour = 0;

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthdayController.dispose();

    if (widget.user.role == UserRole.sitter) {
      _experienceController.dispose();
      _pricingController.dispose();
      _yearsExpController.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    AppUser updated = widget.user.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      birthday: _birthdayController.text.trim(),
    );

    if (widget.user.role == UserRole.vet) {
      // Vet Save Logic
      final specString = _selectedSpecializations.join(', ');

      String scheduleString = '';
      if (_selectedDays.isNotEmpty) {
        scheduleString += _selectedDays.join(', ');
        if (_startTime != null && _endTime != null) {
          scheduleString +=
              ' | ${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}';
        }
      }

      updated = updated.copyWith(
        specialization: specString,
        clinicLocation: _addressController.text.trim(),
        schedule: scheduleString,
      );
    } else if (widget.user.role == UserRole.sitter) {
      // Sitter Save Logic
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service area (State)')),
        );
        return;
      }

      updated = updated.copyWith(
        experience: _experienceController.text.trim(),
        yearsOfExperience: int.tryParse(_yearsExpController.text.trim()),
        pricing: double.tryParse(_pricingController.text.trim()),
        serviceArea: _selectedState,
        petTypesAccepted: _selectedPetTypes,
        servicesProvided: _selectedServices,
        availableDays: _selectedDays,
        availableHours: {
          'start': _startTime != null ? _formatTime(_startTime!) : '09:00',
          'end': _endTime != null ? _formatTime(_endTime!) : '17:00',
        },
      );
    }

    widget.onSave(updated);
    Navigator.pop(context);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
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

  void _toggleListItem(List<String> list, String item) {
    setState(() {
      if (list.contains(item)) {
        list.remove(item);
      } else {
        list.add(item);
      }
    });
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Generic Info ---
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                label: 'Full name',
                validator: (value) =>
                    AppValidators.required(value, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(controller: _addressController, label: 'Address'),
              const SizedBox(height: 16),
              if (user.role == UserRole.vet)
                _buildMapPlaceholder(_addressController.text),
              const SizedBox(height: 16),
              AppTextField(
                controller: _birthdayController,
                label: 'Birthday (YYYY-MM-DD)',
              ),
              const SizedBox(height: 32),

              // --- Vet Specific ---
              if (user.role == UserRole.vet) ...[
                const Text(
                  'Professional Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Specialization',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  'Working Hours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildAvailabilitySelector(),
              ],

              // --- Sitter Specific ---
              if (user.role == UserRole.sitter) ...[
                const Text(
                  'Professional Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _experienceController,
                  label: 'Experience Description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _yearsExpController,
                  label: 'Years of Experience',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _pricingController,
                  label: 'Hourly Rate (RM)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Service Area (State)',
                    border: OutlineInputBorder(),
                  ),
                  items: _malaysianStates.map((state) {
                    return DropdownMenuItem(value: state, child: Text(state));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedState = val),
                  validator: (v) => v == null ? 'Please select a state' : null,
                ),
                const SizedBox(height: 24),

                const Text(
                  'Pet Types Accepted',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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

                const SizedBox(height: 24),
                const Text(
                  'Services Provided',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _sitterServices
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
                const Text(
                  'Work Availability',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildAvailabilitySelector(),
              ],

              const SizedBox(height: 48),
              PrimaryButton(label: 'Save Changes', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: _daysOfWeek.map((day) {
            final isSelected = _selectedDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (_) => _toggleListItem(_selectedDays, day),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _selectStartTime,
                child: Text(_startTime?.format(context) ?? 'Start Time'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: _selectEndTime,
                child: Text(_endTime?.format(context) ?? 'End Time'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder(String address) {
    // A mock Google Map view
    return Container(
      height: 150,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (_) => const Divider(color: Colors.white),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (_) => const VerticalDivider(color: Colors.white),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 40),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Text(
                  address.isEmpty ? 'Select Address' : address,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
