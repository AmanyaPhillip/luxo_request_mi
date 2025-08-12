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
  final String? imagePath; // This now stores either uploaded file or screenshot path

  UserData({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.realEstateProject,
    required this.unit,
    required this.language,
    this.imagePath,
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
      'imagePath': imagePath,
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
      imagePath: json['imagePath'],
    );
  }

  // Helper method to check if imagePath is a screenshot (contains 'screenshot_')
  bool get hasScreenshot => imagePath != null && imagePath!.contains('screenshot_');
  
  // Helper method to check if imagePath is an uploaded file
  bool get hasUploadedFile => imagePath != null && !imagePath!.contains('screenshot_');
}

// History ticket model
class Ticket {
  final String status; // "Success" or "Fail"
  final DateTime requestDate;
  final UserData submittedData;

  Ticket({
    required this.status,
    required this.requestDate,
    required this.submittedData,
  });

  String get projectName => submittedData.realEstateProject;

  // Helper methods for screenshot handling
  bool get hasScreenshot => submittedData.hasScreenshot;
  String? get screenshotPath => hasScreenshot ? submittedData.imagePath : null;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'requestDate': requestDate.toIso8601String(),
      'submittedData': submittedData.toJson(),
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      status: json['status'] ?? 'Unknown',
      requestDate: DateTime.parse(json['requestDate']),
      submittedData: UserData.fromJson(json['submittedData'] ?? {}),
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

  static String getRequestUrl(String language) {
    return language == 'French'
        ? 'https://dma.immo/request/'
        : 'https://dma.immo/en/request/';
  }
}