import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../models/app_user.dart';
import '../../models/pet.dart';
import '../../utils/app_validators.dart';
import '../../blocs/pet/pet_bloc.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'edit_profile_screen.dart'; // Added back

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final authUser = context.read<AuthBloc>().state.user;
    if (authUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProfileBloc>().add(ProfileRequested(authUser.id));
        context.read<PetBloc>().add(PetsRequested(authUser.id));
      });
    }
  }

  Future<void> _uploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    if (!mounted) return;
    // Copy picked file to a stable temp location and persist path in ProfileBloc
    final pickedPath = result.files.single.path!;
    final authUser = context.read<AuthBloc>().state.user;
    if (authUser == null) return;
    final src = File(pickedPath);
    try {
      final dest = File('${Directory.systemTemp.path}/petpal_profile_${authUser.id}.jpg');
      await src.copy(dest.path);
      context.read<ProfileBloc>().add(ProfileLocalImageSet(path: dest.path, uid: authUser.id));
    } catch (_) {
      // fallback to original path
      context.read<ProfileBloc>().add(ProfileLocalImageSet(path: pickedPath, uid: authUser.id));
    }

  }

  void _openEditScreen(AppUser user) {
    Navigator.pushNamed(
      context,
      EditProfileScreen.routeName,
      arguments: {
        'user': user,
        'onSave': (AppUser updated) {
          context.read<ProfileBloc>().add(ProfileUpdated(updated));
        },
      },
    );
  }

  void _openSettings(AppUser user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context);
              _openEditScreen(user);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Reset Password'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reset_password');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(value: true, onChanged: (val) {}), // Mock
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.settings),
                onPressed: state.user != null ? () => _openSettings(state.user!) : null,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.isLoading && state.user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final user =
              state.user ??
              const AppUser(id: '', name: '', email: '', role: UserRole.owner);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Use the ProfileBloc state passed into the builder so updates reliably rebuild
                Builder(builder: (_) {
                  final localPath = state.localProfileImagePath;
                  ImageProvider? avatarImage;
                  if (localPath != null && localPath.isNotEmpty) {
                    avatarImage = FileImage(File(localPath));
                  } else if (user.profileImageUrl != null) {
                    avatarImage = NetworkImage(user.profileImageUrl!);
                  }
                  return CircleAvatar(
                    radius: 48,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  );
                }),
                TextButton.icon(
                  onPressed: _uploadImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload photo'),
                ),
                const SizedBox(height: 16),
                // Personal Info Section
                _buildInfoSection(context, user),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                _buildPetList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, AppUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, user.name),
            const Divider(),
            _buildInfoRow(Icons.email, user.email),
            const Divider(),
            _buildInfoRow(Icons.phone, user.phone ?? 'N/A'),
            const Divider(),
            _buildInfoRow(Icons.location_on, user.address ?? 'N/A'),
            if (user.birthday != null) ...[
              const Divider(),
              _buildInfoRow(Icons.cake, user.birthday!),
            ],
            if (user.role == UserRole.vet) ...[
              const Divider(),
              _buildInfoRow(Icons.medical_services, user.specialization ?? 'N/A', label: 'Specialization'),
              const Divider(),
              _buildInfoRow(Icons.local_hospital, user.clinicLocation ?? 'N/A', label: 'Clinic'),
            ],
            if (user.role == UserRole.sitter) ...[
              const Divider(),
              _buildInfoRow(Icons.work_history, user.experience ?? 'N/A', label: 'Experience'),
              const Divider(),
              _buildInfoRow(Icons.attach_money, user.pricing != null ? '\$${user.pricing}/hr' : 'N/A', label: 'Rate'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, {String? label}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               if (label != null) ...[
                 Text(
                   label,
                   style: const TextStyle(fontSize: 12, color: Colors.grey),
                 ),
                 const SizedBox(height: 2),
               ],
               Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
             ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetList() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, pState) {
        final currentUser = pState.user ?? context.read<AuthBloc>().state.user;
        if (currentUser != null && (currentUser.role == UserRole.sitter || currentUser.role == UserRole.vet)) {
          return const SizedBox.shrink();
        }
        return BlocBuilder<PetBloc, PetState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Pets',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/pets/form'),
                      child: const Text('Add Pet'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.isLoading && state.pets.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (state.pets.isEmpty)
                  const Text('No pets added yet.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.pets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final pet = state.pets[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: () {
                              if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
                                final f = File(pet.imageUrl!);
                                if (f.existsSync()) return FileImage(f) as ImageProvider;
                                return NetworkImage(pet.imageUrl!);
                              }
                              return null;
                            }(),
                            child: pet.imageUrl == null || pet.imageUrl!.isEmpty
                                ? Text(pet.name[0].toUpperCase())
                                : null,
                          ),
                          title: Text(pet.name),
                          subtitle: Text('${pet.species} • ${pet.breed}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/pets/detail',
                            arguments: pet,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
