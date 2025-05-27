class MesuresCorporelles {
  String id;
  DateTime date;
  double poids; // en kg
  double? tauxGraisse; // en pourcentage
  double? tauxEau; // en pourcentage
  double? masseMuscle; // en kg
  double? masseOsseuse; // en kg
  double? metabolismeBasal; // en kcal
  String? notes;

  MesuresCorporelles({
    required this.id,
    required this.date,
    required this.poids,
    this.tauxGraisse,
    this.tauxEau,
    this.masseMuscle,
    this.masseOsseuse,
    this.metabolismeBasal,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'poids': poids,
      'tauxGraisse': tauxGraisse,
      'tauxEau': tauxEau,
      'masseMuscle': masseMuscle,
      'masseOsseuse': masseOsseuse,
      'metabolismeBasal': metabolismeBasal,
      'notes': notes,
    };
  }

  factory MesuresCorporelles.fromMap(Map<String, dynamic> map) {
    return MesuresCorporelles(
      id: map['id'],
      date: DateTime.parse(map['date']),
      poids: map['poids'],
      tauxGraisse: map['tauxGraisse'],
      tauxEau: map['tauxEau'],
      masseMuscle: map['masseMuscle'],
      masseOsseuse: map['masseOsseuse'],
      metabolismeBasal: map['metabolismeBasal'],
      notes: map['notes'],
    );
  }
} 