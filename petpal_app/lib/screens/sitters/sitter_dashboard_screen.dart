import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../models/app_user.dart';
import '../../models/pet.dart';
import '../../repositories/pet_repository.dart';
import '../../models/booking.dart';
import '../../utils/dialog_utils.dart';
import 'sitter_profile_setup_screen.dart';

class SitterDashboardScreen extends StatefulWidget {
  const SitterDashboardScreen({super.key});

  @override
  State<SitterDashboardScreen> createState() => _SitterDashboardScreenState();
}

class _SitterDashboardScreenState extends State<SitterDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      // Check if profile is complete. If not, redirect? 
      // Prompt says: "Incomplete sitter profile → redirect to profile setup"
      // Basic check: if yearsOfExperience or servicesProvided are empty/null.
      if ((user.servicesProvided == null || user.servicesProvided!.isEmpty) && user.role == UserRole.sitter) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             Navigator.pushNamed(context, SitterProfileSetupScreen.routeName);
          });
      }

      context.read<BookingBloc>().add(
        ProviderBookingsRequested(userId: user.id, role: user.role),
      );
    }
  }

  final Map<String, Pet> _petCache = {};
  final Set<String> _ownersFetched = {};
  bool _isLoadingData = false;

  Future<void> _loadBookingData(List<Booking> bookings) async {
    if (_isLoadingData) return;
    setState(() => _isLoadingData = true);
    final petRepo = context.read<PetRepository>();
    for (final booking in bookings) {
      if (!_ownersFetched.contains(booking.ownerId)) {
        try {
          final pets = await petRepo.fetchPets(booking.ownerId);
          for (final pet in pets) {
            _petCache[pet.id] = pet;
          }
        } catch (_) {}
        _ownersFetched.add(booking.ownerId);
      }
    }
    if (mounted) setState(() => _isLoadingData = false);
  }

  ImageProvider? _imageProviderFromUrl(String? url) {
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
    // Only use NetworkImage for http/https
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return null;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateStatus(Booking booking, BookingStatus status, [String? reason]) {
    final updatedBooking = reason != null 
       ? booking.copyWith(rejectionReason: reason)
       : booking;
       
    context.read<BookingBloc>().add(BookingStatusUpdated(updatedBooking, status));
  }
  
  void _showRejectDialog(Booking booking) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Schedule conflict...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reason is required')));
                 return;
              }
              _updateStatus(booking, BookingStatus.rejected, reasonController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
           if (state.errorMessage != null) {
              DialogUtils.showErrorDialog(context, state.errorMessage!);
           }
        },
        builder: (context, state) {
          if (state.isLoading && state.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final bookings = state.bookings;
          
          final pending = bookings.where((b) => b.status == BookingStatus.pending).toList()
             ..sort((a,b) => a.date.compareTo(b.date));
          final upcoming = bookings.where((b) => b.status == BookingStatus.accepted).toList()
             ..sort((a,b) => a.date.compareTo(b.date));

          
          final completed = bookings.where((b) => b.status == BookingStatus.completed).toList()
             ..sort((a,b) => b.date.compareTo(a.date)); // Newest first
          final rejected = bookings.where((b) => b.status == BookingStatus.rejected).toList()
             ..sort((a,b) => b.date.compareTo(a.date));

          if ((pending.isNotEmpty || upcoming.isNotEmpty) && !_isLoadingData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadBookingData([...pending, ...upcoming]);
            });
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(pending, isPending: true),
              _buildBookingList(upcoming),
              _buildBookingList(completed),
              _buildBookingList(rejected),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, {bool isPending = false}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No bookings found', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index], isPending);
      },
    );
  }

  Widget _buildBookingCard(Booking booking, bool isPending) {
    final pet = _petCache[booking.petId];
    final image = _imageProviderFromUrl(booking.petImageUrl ?? pet?.imageUrl);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: image,
                  child: image == null ? Text(booking.petName.isNotEmpty ? booking.petName[0] : '?') : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.petName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${booking.serviceType ?? "Sitting"}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${DateFormat('MMM d, y').format(booking.date)}${booking.endDate != null ? " - ${DateFormat('MMM d').format(booking.endDate!)}" : ""}'),
              ],
            ),
             if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('"${booking.notes}"', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700])),
             ],
             if (booking.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Text('Reason: ${booking.rejectionReason}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
             ],
             
             if (isPending) ...[
               const SizedBox(height: 16),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   OutlinedButton(
                     onPressed: () => _showRejectDialog(booking),
                     style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                     child: const Text('Reject'),
                   ),
                   const SizedBox(width: 12),
                   ElevatedButton(
                     onPressed: () => _updateStatus(booking, BookingStatus.accepted),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                     child: const Text('Accept'),
                   ),
                 ],
               ),
             ]
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.pending: color = Colors.orange; break;
      case BookingStatus.accepted: color = Colors.green; break;
      case BookingStatus.completed: color = Colors.blue; break;
      case BookingStatus.rejected: color = Colors.red; break;
      case BookingStatus.cancelled: color = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
