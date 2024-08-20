  import 'package:intl/intl.dart';

String formatDateDependingOnCurrentTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date.isAfter(today)) {
      return DateFormat("hh:mm a").format(date);
    } else if (date.year == now.year) {
      return DateFormat('hh:mm a MMM dd').format(date);
    } else {
      return DateFormat('hh:mm a MMM dd, yyyy').format(date);
    }
  }