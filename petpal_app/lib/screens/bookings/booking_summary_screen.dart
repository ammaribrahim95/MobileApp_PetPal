import 'package:flutter/material.dart';
import 'dart:io';

import '../../models/booking.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key, required this.booking});

  static const routeName = '/bookings/summary';

  final Booking booking;

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
    if (url.startsWith('http://') || url.startsWith('https://')) return NetworkImage(url);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking summary')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: _imageProviderFromUrl(booking.petImageUrl) ?? const AssetImage('assets/images/pet_placeholder.png'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.petName, style: theme.titleLarge),
                          const SizedBox(height: 6),
                          Text(booking.petBreed ?? '', style: theme.bodyMedium),
                          const SizedBox(height: 8),
                          Text(booking.type.name.toUpperCase(), style: theme.bodySmall?.copyWith(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(booking.status.name.toUpperCase(), style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Booking ID', booking.id),
                    const Divider(),
                    _detailRow('Date', _formatDate(booking.date)),
                    if (booking.time != null) ...[
                      const Divider(),
                      _detailRow('Time', booking.time!),
                    ],
                    if (booking.endDate != null) ...[
                      const Divider(),
                      _detailRow('End date', _formatDate(booking.endDate!)),
                    ],
                    const Divider(),
                    _detailRow('Notes', booking.notes ?? 'None'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: cancel booking
                    },
                    child: const Text('Cancel Booking'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, ModalRoute.withName('/home'));
                    },
                    child: const Text('Back to dashboard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.black54))),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}' ;
  }
}
