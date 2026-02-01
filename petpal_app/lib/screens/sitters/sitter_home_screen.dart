import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../../blocs/profile/profile_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../models/booking.dart';
import '../../widgets/primary_button.dart';

class SitterHomeScreen extends StatelessWidget {
  const SitterHomeScreen({super.key});

  static ImageProvider? _imageProviderFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'file') {
        final path = uri.toFilePath();
        final f = File(path);
        if (f.existsSync()) return FileImage(f) as ImageProvider;
        return null;
      }
    } catch (_) {}
    try {
      final f = File(url);
      if (f.existsSync()) return FileImage(f) as ImageProvider;
    } catch (_) {}
    if (url.startsWith('http://') || url.startsWith('https://')) return NetworkImage(url);
    return null;
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    
    // Trigger data fetch if needed, though SitterDashboard might have done it.
    // Ideally duplicate fetch or rely on cached state in Bloc.
    // We'll trust the Bloc has data or will load it.
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.name ?? "Sitter"}!', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  // Ensure the ProfileBloc has loaded the current user's profile
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
                    radius: 18,
                    backgroundImage: avatarImage,
                    child: avatarImage == null ? const Icon(Icons.person, size: 20) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state.isLoading && state.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final bookings = state.bookings;
          final pending = bookings.where((b) => b.status == BookingStatus.pending).toList();
          final upcoming = bookings.where((b) => b.status == BookingStatus.accepted && b.date.isAfter(DateTime.now())).toList()
            ..sort((a,b) => a.date.compareTo(b.date));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlight Stats
                Row(
                  children: [
                    _buildStatCard(context, 'Pending', pending.length.toString(), Colors.orange),
                    const SizedBox(width: 16),
                    _buildStatCard(context, 'Upcoming', upcoming.length.toString(), Colors.blue),
                  ],
                ),
                const SizedBox(height: 32),

                // Pending Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pending Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (pending.isNotEmpty)
                      TextButton(onPressed: () {}, child: const Text('See All')),
                  ],
                ),
                const SizedBox(height: 8),
                if (pending.isEmpty) _buildEmptyState('No pending requests'),
                ...pending.take(2).map((b) => _buildBookingTile(b, context)).toList(),

                const SizedBox(height: 32),

                // Upcoming Section
                const Text('Next Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (upcoming.isEmpty) 
                  _buildEmptyState('No upcoming appointments')
                else ...[
                  // Show all upcoming appointments; highlight the earliest one
                  ...upcoming.map((b) => _buildBookingTile(b, context, highlight: b == upcoming.first)).toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTile(Booking booking, BuildContext context, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
        border: highlight ? Border.all(color: Theme.of(context).primaryColor) : Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!highlight) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: _imageProviderFromUrl(booking.petImageUrl),
            child: _imageProviderFromUrl(booking.petImageUrl) == null ? Text(booking.petName[0]) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.petName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d').format(booking.date)} • ${booking.serviceType ?? "Sitting"}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          if (highlight)
            const Chip(label: Text('Next'), backgroundColor: Colors.blue, labelStyle: TextStyle(color: Colors.white, fontSize: 10))
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
    );
  }
}
