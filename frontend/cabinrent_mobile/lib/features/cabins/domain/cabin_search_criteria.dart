class CabinSearchCriteria {
  const CabinSearchCriteria({
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  int get nights => checkOut.difference(checkIn).inDays;
}
