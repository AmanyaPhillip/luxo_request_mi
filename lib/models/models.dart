// User data model
class UserData {
  final String title;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String realEstateProject;
  final String unit;
  final String language;

  UserData({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.realEstateProject,
    required this.unit,
    required this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'realEstateProject': realEstateProject,
      'unit': unit,
      'language': language,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      title: json['title'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      realEstateProject: json['realEstateProject'] ?? '',
      unit: json['unit'] ?? '',
      language: json['language'] ?? 'English',
    );
  }
}

// History ticket model
class Ticket {
  final String projectName;
  final String status; // "Success" or "Fail"
  final DateTime requestDate;

  Ticket({
    required this.projectName,
    required this.status,
    required this.requestDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectName': projectName,
      'status': status,
      'requestDate': requestDate.toIso8601String(),
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      projectName: json['projectName'] ?? '',
      status: json['status'] ?? 'Unknown',
      requestDate: DateTime.parse(json['requestDate']),
    );
  }
}

class Language {
  final String name;
  final String nativeName;

  const Language({required this.name, required this.nativeName});
}

// Constants for dropdown values
class Constants {
  static const List<String> titles = ['Mr.', 'Mrs.'];
  
  static const List<String> realEstateProjects = [
    'La Suite',
    'L\'Aristocrate',
    'Domaine des Méandres',
    'Villas Cortina',
    'Le Divin',
    'Le WOW',
    'Le 696 St-Jean',
    '550 St-Jean (Stationnement)',
    'LUXO',
    'Frontenac',
  ];

  static const List<Language> languages = [
    Language(name: 'English', nativeName: 'English'),
    Language(name: 'French', nativeName: 'Français'),
  ];
  
  // URL mapping
  static String getRequestUrl(String language) {
    return language == 'French' 
        ? 'https://dma.immo/request/' 
        : 'https://dma.immo/en/request/';
  }
}