import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/pet/pet_bloc.dart';
import '../../models/pet.dart';
import '../../utils/dialog_utils.dart';
import 'pet_form_screen.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key});

  static const routeName = '/pets/detail';

  @override
  Widget build(BuildContext context) {
    // We expect the Pet object to be passed via arguments
    final pet = ModalRoute.of(context)!.settings.arguments as Pet;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(
          color: Colors.black,
        ), // Ensure visibility on light bg
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          60,
          24,
          24,
        ), // Add top padding for AppBar
        child: Column(
          children: [
            _buildPetHeader(pet),
            const SizedBox(height: 32),
            _buildBasicInfoCard(pet),
            const SizedBox(height: 24),
            _buildMedicalHistoryCard(context, pet),
            const SizedBox(height: 32),
            _buildActionButtons(context, pet),
          ],
        ),
      ),
    );
  }

  Widget _buildPetHeader(Pet pet) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 70,
            backgroundColor: Colors.grey[200],
            backgroundImage: () {
              if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
                final f = File(pet.imageUrl!);
                if (f.existsSync()) return FileImage(f) as ImageProvider;
                return NetworkImage(pet.imageUrl!);
              }
              return null;
            }(),
            child: pet.imageUrl == null || pet.imageUrl!.isEmpty
                ? const Icon(Icons.pets, size: 64, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          pet.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${pet.species} • ${pet.breed}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard(Pet pet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.cake, 'Age', '${pet.age} years'),
                _buildContainerDivider(),
                _buildInfoItem(
                  pet.gender.toLowerCase() == 'male'
                      ? Icons.male
                      : Icons.female,
                  'Gender',
                  pet.gender,
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.monitor_weight,
                  'Weight',
                  '${pet.weight} kg',
                ),
                _buildContainerDivider(),
                _buildInfoItem(
                  pet.isVaccinated ? Icons.check_circle : Icons.cancel,
                  'Vaccinated',
                  pet.isVaccinated ? 'Yes' : 'No',
                  iconColor: pet.isVaccinated ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[300]);
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? Colors.grey[600], size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMedicalHistoryCard(BuildContext context, Pet pet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical History',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMedicalRow('Allergies', pet.allergies),
            const Divider(),
            _buildMedicalRow('Conditions', pet.medicalConditions),
            const Divider(),
            _buildMedicalRow('Notes', pet.medicalHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRow(String label, String? value) {
    final hasValue = value != null && value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hasValue ? value : 'None',
              style: TextStyle(
                color: hasValue ? Colors.black87 : Colors.grey[400],
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Pet pet) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(
              context,
              PetFormScreen.routeName,
              arguments: pet,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Edit Pet'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final confirmed = await DialogUtils.showConfirmationDialog(
                context,
                title: 'Delete Pet',
                message:
                    'Are you sure you want to remove ${pet.name}? This action cannot be undone.',
              );
              if (confirmed) {
                if (context.mounted) {
                  context.read<PetBloc>().add(PetDeleted(pet.id));
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50], // Soft red
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete Pet'),
          ),
        ),
      ],
    );
  }
}
