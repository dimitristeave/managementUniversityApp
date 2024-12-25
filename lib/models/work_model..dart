// lib/models/work_model.dart
class Work {
  final String company;
  final String section;
  final String address;
  final String description;
  final String link;

  Work({
    required this.company,
    required this.section,
    required this.address,
    required this.description,
    required this.link,
  });

  // Factory constructor pour créer un objet Work à partir d'un JSON
  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      company: json['company'],
      section: json['section'],
      address: json['address'],
      description: json['description'],
      link: json['link'],
    );
  }
}
