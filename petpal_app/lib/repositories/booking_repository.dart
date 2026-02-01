
import '../models/booking.dart';
import '../services/firestore_service.dart';

class BookingRepository {
  BookingRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<void> createBooking(Booking booking) async {
    final collection = booking.type == BookingType.vet
        ? _firestoreService.vetBookingsRef()
        : _firestoreService.sitterBookingsRef();
    await _firestoreService.setDocument(
      collection: collection,
      docId: booking.id,
      data: booking.toMap(),
    );
  }

  Future<List<Booking>> fetchOwnerBookings(String ownerId) async {
    final vetSnapshot = await _firestoreService.queryCollection(
      collection: _firestoreService.vetBookingsRef(),
      builder: (query) => query.where('ownerId', isEqualTo: ownerId),
    );
    final sitterSnapshot = await _firestoreService.queryCollection(
      collection: _firestoreService.sitterBookingsRef(),
      builder: (query) => query.where('ownerId', isEqualTo: ownerId),
    );

    final vetBookings = vetSnapshot.docs
        .map((doc) => Booking.fromMap(doc.id, doc.data(), BookingType.vet))
        .toList();
    final sitterBookings = sitterSnapshot.docs
        .map((doc) => Booking.fromMap(doc.id, doc.data(), BookingType.sitter))
        .toList();
    return [...vetBookings, ...sitterBookings];
  }

  Future<List<Booking>> fetchVetBookings(String vetId) async {
    final snapshot = await _firestoreService.queryCollection(
      collection: _firestoreService.vetBookingsRef(),
      builder: (query) => query.where('vetId', isEqualTo: vetId),
    );
    return snapshot.docs
        .map((doc) => Booking.fromMap(doc.id, doc.data(), BookingType.vet))
        .toList();
  }

  Future<List<Booking>> fetchSitterBookings(String sitterId) async {
    final snapshot = await _firestoreService.queryCollection(
      collection: _firestoreService.sitterBookingsRef(),
      builder: (query) => query.where('sitterId', isEqualTo: sitterId),
    );
    return snapshot.docs
        .map((doc) => Booking.fromMap(doc.id, doc.data(), BookingType.sitter))
        .toList();
  }

  Future<void> updateStatus({
    required Booking booking,
    required BookingStatus status,
  }) async {
    final collection = booking.type == BookingType.vet
        ? _firestoreService.vetBookingsRef()
        : _firestoreService.sitterBookingsRef();

    final data = <String, dynamic>{'status': status.name};
    if (booking.rejectionReason != null) {
      data['rejectionReason'] = booking.rejectionReason;
    }

    if (_firestoreService == null) {
      // defensive: shouldn't happen, but guard
      return;
    }
    try {
      await _firestoreService.setDocument(
        collection: collection,
        docId: booking.id,
        data: data,
      );
    } catch (e) {
      // Log for debugging
      // ignore: avoid_print
      print('Failed to update booking status for ${booking.id}: $e');
      rethrow;
    }
  }
}
