class Exam {
  final int id;
  final String name;
  final String? date;
  final String omrCode;

  Exam({
    required this.id,
    required this.name,
    this.date,
    required this.omrCode,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'],
      name: json['name'],
      date: json['date'],
      omrCode: json['omr_code'],
    );
  }
}
