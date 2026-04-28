class QrDatasource {
  static Map<String, String> parseQrData(String raw) {
    final parts = raw.split(':');
    if (parts.length < 4 || parts[0] != 'TICKET') {
      return {};
    }

    return {'ticketId': parts[1], 'eventId': parts[2], 'seatId': parts[3]};
  }
}
