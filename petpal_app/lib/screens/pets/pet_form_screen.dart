import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/pet/pet_bloc.dart';
import '../../models/pet.dart';
import '../../utils/app_validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, this.pet});

  static const routeName = '/pets/form';

  final Pet? pet;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _historyController;

  String _gender = 'Female';
  bool _isVaccinated = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _nameController = TextEditingController(text: pet?.name);
    _speciesController = TextEditingController(text: pet?.species);
    _breedController = TextEditingController(text: pet?.breed);
    _ageController = TextEditingController(text: pet?.age);
    _weightController = TextEditingController(text: pet?.weight.toString());
    _allergiesController = TextEditingController(text: pet?.allergies);
    _conditionsController = TextEditingController(text: pet?.medicalConditions);
    _historyController = TextEditingController(text: pet?.medicalHistory);

    if (pet != null) {
      _gender = pet.gender;
      _isVaccinated = pet.isVaccinated;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    if (!mounted) return;
    context.read<PetBloc>().add(
      PetImageSelected(File(result.files.single.path!)),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<PetBloc>();
    final ownerId = context.read<AuthBloc>().state.user?.id ?? '';

    // Use uploaded image URL if available, otherwise keep existing or null
    final imageUrl = bloc.state.uploadedImageUrl ?? widget.pet?.imageUrl;

    final pet = Pet(
      id: widget.pet?.id ?? _uuid.v4(),
      ownerId: ownerId,
      name: _nameController.text.trim(),
      species: _speciesController.text.trim(),
      breed: _breedController.text.trim(),
      age: _ageController.text.trim(),
      gender: _gender,
      weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      isVaccinated: _isVaccinated,
      allergies: _allergiesController.text.trim(),
      medicalConditions: _conditionsController.text.trim(),
      medicalHistory: _historyController.text.trim(),
      imageUrl: imageUrl,
      createdAt: widget.pet?.createdAt ?? DateTime.now(),
    );

    if (widget.pet == null) {
      bloc.add(PetCreated(pet));
    } else {
      bloc.add(PetUpdated(pet));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pet == null ? 'Add pet' : 'Edit pet')),
      body: BlocBuilder<PetBloc, PetState>(
        builder: (context, state) {
          final displayImage = state.uploadedImageUrl ?? widget.pet?.imageUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _uploadImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: () {
                              if (displayImage != null &&
                                  displayImage.isNotEmpty) {
                                final file = File(displayImage);
                                if (file.existsSync())
                                  return FileImage(file) as ImageProvider;
                                return NetworkImage(displayImage);
                              }
                              return null;
                            }(),
                            child: displayImage == null || displayImage.isEmpty
                                ? const Icon(Icons.pets, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _nameController,
                    label: 'Name',
                    validator: (value) =>
                        AppValidators.required(value, fieldName: 'Name'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _speciesController,
                          label: 'Species',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _breedController,
                          label: 'Breed',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _ageController,
                          label: 'Age (years)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                          ),
                          items: ['Male', 'Female']
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _gender = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _weightController,
                          label: 'Weight (kg)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text(
                            'Vaccinated?',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: _isVaccinated,
                          onChanged: (val) =>
                              setState(() => _isVaccinated = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Medical Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  AppTextField(
                    controller: _allergiesController,
                    label: 'Allergies (Optional)',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _conditionsController,
                    label: 'Medical Conditions (Optional)',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _historyController,
                    label: 'Medical Notes (Optional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Save',
                    isLoading: state.isLoading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
