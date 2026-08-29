// a possible interaction between two of the user's meds
class MedInteraction {
  final String title;
  final String body;

  MedInteraction({required this.title, required this.body});

  factory MedInteraction.fromJson(Map<String, dynamic> json) {
    return MedInteraction(
      title: json['title'] ?? '',
      body: json['body'] ?? '',
    );
  }
}

// short plain-English description of what a medication does
class DrugInfo {
  final String name;
  final String description;

  DrugInfo({required this.name, required this.description});

  factory DrugInfo.fromJson(Map<String, dynamic> json) {
    return DrugInfo(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
