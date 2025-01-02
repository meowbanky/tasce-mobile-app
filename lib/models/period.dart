// lib/models/period.dart

class Period {
  final String periodId;
  final String description;

  Period({
    required this.periodId,
    required this.description,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      periodId: json['periodId'].toString(),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'periodId': periodId,
        'description': description,
      };
}
