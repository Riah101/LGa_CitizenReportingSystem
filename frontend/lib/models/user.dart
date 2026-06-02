enum UserRole {
  citizen,
  mtaaOfficer,    // Mtaa/Shina official
  wardOfficer,    // Ward Executive Officer
  districtOfficer, // District Commissioner
  regionOfficer,  // Regional Commissioner
  nationalOfficer, // National official
  admin,
}

class User {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final String? nationalId;
  
  // Location assignment for officers
  final String? mtaa;
  final String? ward;
  final String? district;
  final String? region;
  
  final DateTime createdAt;
  final bool isVerified;
  final String? profilePhoto;
  int totalComplaints;
  int resolvedComplaints;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.role = UserRole.citizen,
    this.nationalId,
    this.mtaa,
    this.ward,
    this.district,
    this.region,
    required this.createdAt,
    this.isVerified = false,
    this.profilePhoto,
    this.totalComplaints = 0,
    this.resolvedComplaints = 0,
  });

  bool get isOfficer => role != UserRole.citizen;

  String get roleLabel {
    switch (role) {
      case UserRole.citizen:
        return 'Citizen / Raia';
      case UserRole.mtaaOfficer:
        return 'Mtaa Officer / Afisa Mtaa';
      case UserRole.wardOfficer:
        return 'Ward Officer / Afisa Kata';
      case UserRole.districtOfficer:
        return 'District Officer / Afisa Wilaya';
      case UserRole.regionOfficer:
        return 'Regional Officer / Afisa Mkoa';
      case UserRole.nationalOfficer:
        return 'National Officer / Afisa Kitaifa';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.name,
        'nationalId': nationalId,
        'mtaa': mtaa,
        'ward': ward,
        'district': district,
        'region': region,
        'createdAt': createdAt.toIso8601String(),
        'isVerified': isVerified,
        'profilePhoto': profilePhoto,
        'totalComplaints': totalComplaints,
        'resolvedComplaints': resolvedComplaints,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        email: json['email'],
        role: UserRole.values.byName(json['role'] ?? 'citizen'),
        nationalId: json['nationalId'],
        mtaa: json['mtaa'],
        ward: json['ward'],
        district: json['district'],
        region: json['region'],
        createdAt: DateTime.parse(json['createdAt']),
        isVerified: json['isVerified'] ?? false,
        profilePhoto: json['profilePhoto'],
        totalComplaints: json['totalComplaints'] ?? 0,
        resolvedComplaints: json['resolvedComplaints'] ?? 0,
      );
}
