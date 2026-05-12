import 'package:equatable/equatable.dart';

class BadgeEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final String description;
  final String? iconUrl;
  final String rarity; // common|rare|epic|legendary
  final int xpReward;
  final bool unlocked;
  final DateTime? unlockedAt;

  const BadgeEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.rarity,
    required this.xpReward,
    required this.unlocked,
    this.unlockedAt,
  });

  @override
  List<Object?> get props =>
      [id, code, name, description, rarity, xpReward, unlocked, unlockedAt];
}
