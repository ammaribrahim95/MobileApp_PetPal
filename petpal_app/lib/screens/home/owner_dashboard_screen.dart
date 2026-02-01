import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../../blocs/profile/profile_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/pet/pet_bloc.dart';
import '../../models/booking.dart';
import '../../models/pet.dart';
import '../bookings/booking_summary_screen.dart';
import '../pets/pet_detail_screen.dart';
import '../pets/pet_form_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.name ?? 'Pet Parent'}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            context.read<PetBloc>().add(PetsRequested(user.id));
            context.read<BookingBloc>().add(BookingsRequested(user.id));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingSection(context),
              const SizedBox(height: 24),
              _buildMyPetsSection(context),
              const SizedBox(height: 24),
              _buildUpcomingAppointmentsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    
    return Row(
      children: [
        Expanded(
          child: const Text(
            'Glad to see you again!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
         GestureDetector(
           onTap: () => _showProfileMenu(context),
           child: BlocBuilder<ProfileBloc, ProfileState>(
             builder: (context, profileState) {
               // If ProfileBloc hasn't loaded this user's profile, request it once
               if (user != null && (profileState.user == null || profileState.user!.id != user.id)) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                   context.read<ProfileBloc>().add(ProfileRequested(user.id));
                 });
               }
               final localPath = profileState.localProfileImagePath;
               ImageProvider? avatarImage;
               if (localPath != null) {
                 avatarImage = FileImage(File(localPath));
               } else if (user?.profileImageUrl != null) {
                 avatarImage = NetworkImage(user!.profileImageUrl!);
               }
               return CircleAvatar(
                 radius: 24,
                 backgroundImage: avatarImage,
                 child: avatarImage == null ? const Icon(Icons.person) : null,
               );
             },
           ),
         ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Pets',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, PetFormScreen.routeName);
              },
              child: const Text('Add Pet'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<PetBloc, PetState>(
          builder: (context, state) {
            // If pets haven't been loaded yet, request them once after build.
            final authUser = context.read<AuthBloc>().state.user;
            if (authUser != null && state.pets.isEmpty && !state.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<PetBloc>().add(PetsRequested(authUser.id));
                context.read<BookingBloc>().add(BookingsRequested(authUser.id));
              });
            }
            if (state.isLoading && state.pets.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.pets.isEmpty) {
              return _buildEmptyState('No pets added yet.');
            }
            return SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.pets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final pet = state.pets[index];
                  return _buildPetCard(context, pet);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPetCard(BuildContext context, Pet pet) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          PetDetailScreen.routeName,
          arguments: pet,
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 30,
              backgroundImage: () {
                if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
                  final f = File(pet.imageUrl!);
                  if (f.existsSync()) return FileImage(f) as ImageProvider;
                  return NetworkImage(pet.imageUrl!);
                }
                return null;
              }(),
              child: pet.imageUrl == null || pet.imageUrl!.isEmpty
                  ? const Icon(Icons.pets, size: 30)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              pet.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              pet.species,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Appointments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state.isLoading && state.bookings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final upcoming = state.bookings
                .where((b) =>
                    b.status == BookingStatus.pending ||
                    b.status == BookingStatus.accepted)
                .toList();
            
            if (upcoming.isEmpty) {
              return _buildEmptyState('No upcoming appointments.');
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = upcoming[index];
                return _buildBookingCard(context, booking);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final title = booking.type == BookingType.vet ? 'Vet Appointment' : 'Pet Sitting';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Builder(builder: (ctx) {
          ImageProvider? petImage;
          final url = booking.petImageUrl;
          if (url != null && url.isNotEmpty) {
            try {
              final f = File(url);
              if (f.existsSync()) petImage = FileImage(f);
              else petImage = NetworkImage(url);
            } catch (_) {
              petImage = NetworkImage(url);
            }
          }
          return CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            backgroundImage: petImage,
            child: petImage == null
                ? Icon(
                    booking.type == BookingType.vet ? Icons.medical_services : Icons.home,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
          );
        }),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(dateFormat.format(booking.date)),
        trailing: Chip(
          label: Text(
            booking.status.name.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: _getStatusColor(booking.status).withOpacity(0.2),
          labelStyle: TextStyle(color: _getStatusColor(booking.status)),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            BookingSummaryScreen.routeName,
            arguments: booking,
          );
        },
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.red;
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
