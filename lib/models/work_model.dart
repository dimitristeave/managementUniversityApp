// lib/models/work_model.dart
class Work {
  final String company;
  final String type;
  final String section;
  final String address;
  final String description;
  final String link;
  final String id;

  Work({
    required this.type,
    required this.company,
    required this.section,
    required this.address,
    required this.description,
    required this.link,
    required this.id,
  });

  // Factory constructor pour créer un objet Work à partir d'un JSON
  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      company: json['company'],
      type: json["type"],
      section: json['section'],
      address: json['address'],
      description: json['description'],
      link: json['link'],
      id: json['id'],
    );
  }
}
