import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../models/pet.dart';
import '../../repositories/pet_repository.dart';
import '../../repositories/user_repository.dart';
import '../../utils/dialog_utils.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  static const routeName = '/provider/dashboard';

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final Map<String, Pet> _petCache = {};
  final Map<String, AppUser> _ownerCache = {};
  final Set<String> _ownersFetched = {};
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<BookingBloc>().add(
            ProviderBookingsRequested(userId: user.id, role: user.role),
          );
    }
  }

  ImageProvider? _petImageProvider(Booking booking, Pet? pet) {
    final url = booking.petImageUrl ?? pet?.imageUrl;
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

  Future<void> _loadBookingData(List<Booking> bookings) async {
    if (_isLoadingData) return;
    
    setState(() => _isLoadingData = true);
    
    final petRepo = context.read<PetRepository>();
    final userRepo = context.read<UserRepository>();
    
    for (final booking in bookings) {
      // Fetch all pets for an owner once (more reliable than depending on petId presence)
      if (!_ownersFetched.contains(booking.ownerId)) {
        try {
          final pets = await petRepo.fetchPets(booking.ownerId);
          for (final pet in pets) {
            _petCache[pet.id] = pet;
          }
        } catch (e) {
          // Handle error silently
        }
        _ownersFetched.add(booking.ownerId);
      }
      
      // Fetch owner data if not cached
      if (!_ownerCache.containsKey(booking.ownerId)) {
        try {
          final owner = await userRepo.fetchUser(booking.ownerId);
          _ownerCache[booking.ownerId] = owner;
        } catch (e) {
          // Handle error silently
        }
      }
    }
    
    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  void _updateStatus(Booking booking, BookingStatus status) {
    context.read<BookingBloc>().add(BookingStatusUpdated(booking, status));
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
  
  String _getGreeting(AppUser user) {
    if (user.role == UserRole.vet) {
      // Try to extract last name if possible, otherwise use full name
      final names = user.name.split(' ');
      final lastName = names.length > 1 ? names.last : user.name;
      return 'Welcome Dr. $lastName';
    }
    return 'Welcome, ${user.name}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              DialogUtils.showErrorDialog(context, state.errorMessage!);
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.bookings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final pending = state.bookings
                .where((b) => b.status == BookingStatus.pending)
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
            
            final upcoming = state.bookings
                .where((b) => b.status == BookingStatus.accepted)
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            // Load pet and owner data for cards we show
            if ((pending.isNotEmpty || upcoming.isNotEmpty) && !_isLoadingData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadBookingData([...pending, ...upcoming]);
              });
            }

            

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Header
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               _getGreeting(user),
                               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               'Here is your schedule for today.',
                               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                 color: Colors.grey[600],
                               ),
                             ),
                           ],
                         ),
                       ),
                       GestureDetector(
                         onTap: () => _showProfileMenu(context),
                         child: CircleAvatar(
                           backgroundImage: user.profileImageUrl != null
                               ? NetworkImage(user.profileImageUrl!)
                               : null,
                           child: user.profileImageUrl == null
                               ? const Icon(Icons.person)
                               : null,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 32),

                   // Pending Bookings Section
                   if (pending.isNotEmpty) ...[
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           'Pending Requests (${pending.length})',
                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),
                     SizedBox(
                       height: 280, // Height for horizontal cards
                       child: ListView.builder(
                         scrollDirection: Axis.horizontal,
                         itemCount: pending.length,
                         itemBuilder: (context, index) => _buildPendingCard(pending[index]),
                       ),
                     ),
                   ] else ...[
                      // Empty pending state if needed, or just hide
                      Text(
                         'Pending Requests',
                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 16),
                       Container(
                         padding: const EdgeInsets.all(24),
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: Colors.grey[100],
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: Colors.grey[300]!),
                         ),
                         child: const Center(child: Text('No pending requests')),
                       ),
                   ],

                   const SizedBox(height: 32),

                   // Upcoming Appointments Section
                   Text(
                     'Upcoming Appointments',
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: 16),
                   if (upcoming.isEmpty)
                     const Center(child: Text('No upcoming appointments.'))
                   else
                     ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: upcoming.length,
                       itemBuilder: (context, index) => _buildUpcomingCard(upcoming[index]),
                     ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingCard(Booking booking) {
    final pet = _petCache[booking.petId];
    final owner = _ownerCache[booking.ownerId];
    final image = _petImageProvider(booking, pet);
    
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
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
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: image,
                backgroundColor: Colors.orange[100],
                child: image == null ? const Icon(Icons.pets, color: Colors.orange) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner?.name ?? booking.ownerName ?? 'Loading...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      owner?.email ?? booking.ownerEmail ?? 'Loading...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.pets, 'Pet', (booking.petName.isNotEmpty ? booking.petName : (pet?.name ?? ''))),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.category, 'Species', booking.petSpecies ?? pet?.species ?? 'N/A'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.class_, 'Breed', booking.petBreed ?? pet?.breed ?? 'N/A'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.calendar_today, 'Date', DateFormat.MMMd().format(booking.date)),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.access_time, 'Time', booking.time ?? "Not specified"),
          const SizedBox(height: 12),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${booking.notes}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus(booking, BookingStatus.cancelled),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(booking, BookingStatus.accepted),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(Booking booking) {
    final pet = _petCache[booking.petId];
    final owner = _ownerCache[booking.ownerId];
    final image = _petImageProvider(booking, pet);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
           Container(
             width: 60,
             height: 60,
             decoration: BoxDecoration(
               color: Colors.blue[50],
               borderRadius: BorderRadius.circular(12),
             ),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(
                   DateFormat.d().format(booking.date),
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue),
                 ),
                 Text(
                   DateFormat.MMM().format(booking.date).toUpperCase(),
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                 ),
               ],
             ),
           ),
           const SizedBox(width: 12),
           CircleAvatar(
             radius: 28,
             backgroundImage: image,
             backgroundColor: Colors.blue[50],
             child: image == null ? const Icon(Icons.pets, color: Colors.blue) : null,
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (booking.petName.isNotEmpty ? booking.petName : (pet?.name ?? '')),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (kDebugMode)
                          Text('petId: ${booking.petId} id: ${booking.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                 const SizedBox(height: 4),
                 Text(
                   owner?.name ?? booking.ownerName ?? 'Loading...',
                   style: TextStyle(color: Colors.grey[700], fontSize: 13),
                   overflow: TextOverflow.ellipsis,
                 ),
                 Text(
                   owner?.email ?? booking.ownerEmail ?? 'Loading...',
                   style: TextStyle(color: Colors.grey[600], fontSize: 12),
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 6),
                 _buildInfoRow(Icons.category, 'Species', booking.petSpecies ?? pet?.species ?? 'N/A'),
                 const SizedBox(height: 4),
                 _buildInfoRow(Icons.class_, 'Breed', booking.petBreed ?? pet?.breed ?? 'N/A'),
                 const SizedBox(height: 4),
                 _buildInfoRow(Icons.access_time, 'Time', booking.time ?? 'TBD'),
                 if (booking.notes != null && booking.notes!.isNotEmpty)
                   Padding(
                     padding: const EdgeInsets.only(top: 6),
                     child: Text(
                       booking.notes!,
                       style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
               ],
             ),
           ),
           IconButton(
             icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
             onPressed: () => _updateStatus(booking, BookingStatus.completed), // Quick complete action
             tooltip: 'Mark Completed',
           ),
        ],
      ),
    );
  }
}
