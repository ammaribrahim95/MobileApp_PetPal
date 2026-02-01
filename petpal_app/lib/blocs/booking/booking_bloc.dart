import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/booking.dart';
import '../../models/app_user.dart';
import '../../repositories/booking_repository.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc(this._bookingRepository) : super(const BookingState.initial()) {
    on<BookingsRequested>(_onBookingsRequested);
    on<ProviderBookingsRequested>(_onProviderBookingsRequested);
    on<BookingCreated>(_onBookingCreated);
    on<BookingStatusUpdated>(_onStatusUpdated);
  }

  final BookingRepository _bookingRepository;
  final _uuid = const Uuid();

  Future<void> _onBookingsRequested(
    BookingsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final bookings = await _bookingRepository.fetchOwnerBookings(
        event.ownerId,
      );
      emit(state.copyWith(isLoading: false, bookings: bookings));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onProviderBookingsRequested(
    ProviderBookingsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final bookings = event.role == UserRole.vet
          ? await _bookingRepository.fetchVetBookings(event.userId)
          : await _bookingRepository.fetchSitterBookings(event.userId);
      emit(state.copyWith(isLoading: false, bookings: bookings));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onBookingCreated(
    BookingCreated event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final booking = event.booking.id.isEmpty
          ? event.booking.copyWith(id: _uuid.v4())
          : event.booking;
      await _bookingRepository.createBooking(booking);
      emit(
        state.copyWith(
          isLoading: false,
          bookings: [...state.bookings, booking],
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onStatusUpdated(
    BookingStatusUpdated event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      if (kDebugMode) {
        debugPrint('BookingStatusUpdated called for id=${event.booking.id} status=${event.status}');
      }
      await _bookingRepository.updateStatus(
        booking: event.booking,
        status: event.status,
      );
      final updated = state.bookings
          .map(
            (b) => b.id == event.booking.id
                ? event.booking.copyWith(status: event.status)
                : b,
          )
          .toList();
      emit(state.copyWith(isLoading: false, bookings: updated));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}
