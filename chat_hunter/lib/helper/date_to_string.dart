import 'package:intl/intl.dart';

String dateToString(DateTime date) {
  DateTime compare = DateTime.parse(DateFormat('yyyy-MM-dd').format(DateTime.now()));
  DateTime dates = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
  final compares = dates.difference(compare).inDays;
  if (compares == 0) {
    return 'Hari Ini';
  } else if (compares == -1) {
    return 'Kemarin';
  } else {
    return DateFormat('dd MMM').format(date);
  }
}

String dateToStringList(DateTime date) {
  DateTime compare = DateTime.parse(DateFormat('yyyy-MM-dd').format(DateTime.now()));
  DateTime dates = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
  final compares = dates.difference(compare).inDays;
  if (compares == 0) {
    return DateFormat('HH:mm:ss').format(date);
  } else if (compares == -1) {
    return 'Kemarin';
  } else {
    return DateFormat('dd MMM y').format(date);
  }
}
