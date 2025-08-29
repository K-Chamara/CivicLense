import 'package:flutter/material.dart';

class UserRole {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final UserType userType;
  final int maxAllowed;

  const UserRole({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.userType,
    this.maxAllowed = -1, // -1 means unlimited
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': '#${color.value.toRadixString(16).substring(2)}',
      'userType': userType.toString().split('.').last,
      'maxAllowed': maxAllowed,
    };
  }

  static UserRole fromMap(Map<String, dynamic> map) {
    return UserRole(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: _getIconForRole(map['id']),
      color: _getColorFromHex(map['color']),
      userType: _getUserTypeFromString(map['userType']),
      maxAllowed: map['maxAllowed'] ?? -1,
    );
  }

  static IconData _getIconForRole(String roleId) {
    switch (roleId) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'finance_officer':
        return Icons.account_balance_wallet;
      case 'procurement_officer':
        return Icons.shopping_cart;
      case 'anticorruption_officer':
        return Icons.security;
      case 'citizen':
        return Icons.person;
      case 'journalist':
        return Icons.article;
      case 'community_leader':
        return Icons.people;
      case 'researcher':
        return Icons.school;
      case 'ngo':
        return Icons.business;
      default:
        return Icons.person;
    }
  }

  static Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  static UserType _getUserTypeFromString(String userType) {
    switch (userType) {
      case 'admin':
        return UserType.admin;
      case 'government':
        return UserType.government;
      case 'public':
        return UserType.public;
      default:
        return UserType.public;
    }
  }

  // Predefined roles
  static const List<UserRole> allRoles = [
    // Admin (1 user)
    UserRole(
      id: 'admin',
      name: 'System Administrator',
      description: 'Full system management and user administration',
      icon: Icons.admin_panel_settings,
      color: Colors.red,
      userType: UserType.admin,
      maxAllowed: 1,
    ),
    
    // Government Users
    UserRole(
      id: 'finance_officer',
      name: 'Finance Officer',
      description: 'Budget management and financial oversight',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      userType: UserType.government,
      maxAllowed: 1,
    ),
    UserRole(
      id: 'procurement_officer',
      name: 'Procurement Officer',
      description: 'Tender management and procurement oversight',
      icon: Icons.shopping_cart,
      color: Colors.orange,
      userType: UserType.government,
      maxAllowed: 1,
    ),
    UserRole(
      id: 'anticorruption_officer',
      name: 'Anti-corruption Officer',
      description: 'Concern and anti-corruption management',
      icon: Icons.security,
      color: Colors.purple,
      userType: UserType.government,
      maxAllowed: 3,
    ),
    
    // Public Users (Unlimited)
    UserRole(
      id: 'citizen',
      name: 'Citizen/Taxpayer',
      description: 'Track public spending and raise concerns',
      icon: Icons.person,
      color: Colors.blue,
      userType: UserType.public,
    ),
    UserRole(
      id: 'journalist',
      name: 'Journalist/Media User',
      description: 'Publish reports and access media resources',
      icon: Icons.article,
      color: Colors.teal,
      userType: UserType.public,
    ),
    UserRole(
      id: 'community_leader',
      name: 'Community Leader/Activist',
      description: 'Lead communities and organize initiatives',
      icon: Icons.people,
      color: Colors.indigo,
      userType: UserType.public,
    ),
    UserRole(
      id: 'researcher',
      name: 'Researcher/Academic User',
      description: 'Access research data and generate reports',
      icon: Icons.school,
      color: Colors.deepPurple,
      userType: UserType.public,
    ),
    UserRole(
      id: 'ngo',
      name: 'NGO/Private Contractor',
      description: 'Manage projects and access contractor tools',
      icon: Icons.business,
      color: Colors.brown,
      userType: UserType.public,
    ),
  ];

  // Get roles by user type
  static List<UserRole> getRolesByType(UserType userType) {
    return allRoles.where((role) => role.userType == userType).toList();
  }

  // Get public roles (for registration)
  static List<UserRole> get publicRoles => getRolesByType(UserType.public);

  // Get government roles (for admin to create)
  static List<UserRole> get governmentRoles => getRolesByType(UserType.government);

  // Get admin role
  static UserRole get adminRole => allRoles.firstWhere((role) => role.id == 'admin');
}

enum UserType {
  admin,
  government,
  public,
}
