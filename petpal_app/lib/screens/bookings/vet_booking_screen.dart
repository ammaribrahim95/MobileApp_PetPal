import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/pet/pet_bloc.dart';
import '../../models/booking.dart';
import '../../models/app_user.dart';
import '../../screens/bookings/booking_summary_screen.dart';
import '../../widgets/primary_button.dart';

class VetBookingScreen extends StatefulWidget {
  const VetBookingScreen({super.key});

  static const routeName = '/bookings/vet';

  @override
  State<VetBookingScreen> createState() => _VetBookingScreenState();
}

class _VetBookingScreenState extends State<VetBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _notesController = TextEditingController();
  String? _selectedPetId;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    setState(() {
      if (isStart) {
        _startTime = t;
      } else {
        _endTime = t;
      }
    });
  }

  String _formatTimeOfDay(TimeOfDay? t, BuildContext context) {
    if (t == null) return 'Not set';
    return t.format(context);
  }

  void _submit(AppUser vet) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null || _selectedPetId == null) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end time')));
      return;
    }
    // ensure end is after start
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      return;
    }
    
    // Find the selected pet
    final selectedPet = context.read<PetBloc>().state.pets.firstWhere(
      (pet) => pet.id == _selectedPetId,
    );
    
    final booking = Booking.vet(
      id: '',
      ownerId: user.id,
      petId: _selectedPetId!,
      vetId: vet.id,
      date: _selectedDate,
      time: '${_formatTimeOfDay(_startTime, context)} - ${_formatTimeOfDay(_endTime, context)}',
      notes: _notesController.text,
      status: BookingStatus.pending,
      petName: selectedPet.name,
      petImageUrl: selectedPet.imageUrl,
      ownerName: user.name,
      ownerEmail: user.email,
      petSpecies: selectedPet.species,
      petBreed: selectedPet.breed,
    );
    context.read<BookingBloc>().add(BookingCreated(booking));
    Navigator.pushReplacementNamed(
      context,
      BookingSummaryScreen.routeName,
      arguments: booking,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vet = ModalRoute.of(context)!.settings.arguments as AppUser;
    final pets = context.watch<PetBloc>().state.pets;
    _selectedPetId = _selectedPetId ?? (pets.isNotEmpty ? pets.first.id : null);
    return Scaffold(
      appBar: AppBar(title: Text('Book ${vet.name}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedPetId,
              decoration: const InputDecoration(labelText: 'Select pet'),
              items: pets
                  .map(
                    (pet) =>
                        DropdownMenuItem(value: pet.id, child: Text(pet.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedPetId = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Date'),
              subtitle: Text('${_selectedDate.toLocal().toIso8601String().split('T')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(true),
                  icon: const Icon(Icons.schedule),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start'),
                      Text(_formatTimeOfDay(_startTime, context), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(false),
                  icon: const Icon(Icons.schedule),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End'),
                      Text(_formatTimeOfDay(_endTime, context), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const Spacer(),
            if (pets.isEmpty)
              const Text('Add a pet before booking an appointment.')
            else
              BlocBuilder<BookingBloc, BookingState>(
                builder: (context, state) {
                  return PrimaryButton(
                    label: 'Confirm booking',
                    isLoading: state.isLoading,
                    onPressed: () => _submit(vet),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
