import 'package:equatable/equatable.dart';

class CommunityGroup extends Equatable {
  final String id;
  final String name;
  final String description;
  final String currency;
  final int targetAmountCents;
  final String contributionFrequency;
  final String userRole;
  final int memberCount;
  final int totalContributionsCents;
  final int totalExpensesCents;
  final int netPoolCents;
  final double progressPercent;

  const CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    this.currency = 'ETB',
    required this.targetAmountCents,
    this.contributionFrequency = 'monthly',
    this.userRole = 'member',
    this.memberCount = 1,
    this.totalContributionsCents = 0,
    this.totalExpensesCents = 0,
    this.netPoolCents = 0,
    this.progressPercent = 0.0,
  });

  factory CommunityGroup.fromJson(Map<String, dynamic> json) {
    return CommunityGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] ?? '') as String,
      currency: (json['currency'] ?? 'ETB') as String,
      targetAmountCents: int.parse(json['targetAmountCents']?.toString() ?? '0'),
      contributionFrequency: (json['contributionFrequency'] ?? 'monthly') as String,
      userRole: (json['userRole'] ?? 'member') as String,
      memberCount: json['memberCount'] != null ? int.parse(json['memberCount'].toString()) : 1,
      totalContributionsCents: int.parse(json['totalContributionsCents']?.toString() ?? '0'),
      totalExpensesCents: int.parse(json['totalExpensesCents']?.toString() ?? '0'),
      netPoolCents: int.parse(json['netPoolCents']?.toString() ?? '0'),
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        currency,
        targetAmountCents,
        userRole,
        memberCount,
        netPoolCents,
      ];
}
