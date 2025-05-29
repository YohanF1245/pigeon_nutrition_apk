import 'package:uuid/uuid.dart';

class JourRepas {
  final String id;
  final DateTime date;
  final String repasId;
  final int heure;
  final int minute;

  JourRepas({
    String? id,
    required this.date,
    required this.repasId,
    required this.heure,
    required this.minute,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'repasId': repasId,
      'heure': heure,
      'minute': minute,
    };
  }

  factory JourRepas.fromMap(Map<String, dynamic> map) {
    return JourRepas(
      id: map['id'],
      date: DateTime.parse(map['date']),
      repasId: map['repasId'],
      heure: map['heure'],
      minute: map['minute'],
    );
  }

  JourRepas copyWith({
    DateTime? date,
    String? repasId,
    int? heure,
    int? minute,
  }) {
    return JourRepas(
      id: id,
      date: date ?? this.date,
      repasId: repasId ?? this.repasId,
      heure: heure ?? this.heure,
      minute: minute ?? this.minute,
    );
  }
} 