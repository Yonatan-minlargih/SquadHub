import 'package:flutter/material.dart';

class Squad {
  final String id;
  final String name;
  final int memberCount;
  final String recentActivity;
  final IconData activityIcon;

  Squad({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.recentActivity,
    required this.activityIcon,
  });
}

final List<Squad> mockSquads = [
  Squad(
    id: '1',
    name: 'Weekend Warriors',
    memberCount: 5,
    recentActivity: 'Mikias paid for Pizza',
    activityIcon: Icons.local_pizza,
  ),
  Squad(
    id: '2',
    name: 'Study Group',
    memberCount: 4,
    recentActivity: 'Amha is studying',
    activityIcon: Icons.book,
  ),
  Squad(
    id: '3',
    name: 'Roommates',
    memberCount: 3,
    recentActivity: 'Rent due in 5 days',
    activityIcon: Icons.home,
  ),
];
