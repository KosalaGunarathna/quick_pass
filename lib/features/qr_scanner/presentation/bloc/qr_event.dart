// QR usecases are handled via TicketBloc > ValidateTicketUseCase
// This file is a placeholder for any QR-specific logic

class QrUsecases {
  // Parse raw QR string into components
  static Map<String, String> parseQrData(String raw) {
    // Format: TICKET:ticketId:eventId:seatId
    final parts = raw.split(':');
    if (parts.length < 4 || parts[0] != 'TICKET') return {};
    return {
      'ticketId': parts[1],
      'eventId': parts[2],
      'seatId': parts[3],
    };
  }
}
