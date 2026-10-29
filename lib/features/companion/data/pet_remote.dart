import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/pet_state.dart';

/// Everything that makes up the user's pet, as one copy: its look, its
/// vitals ([state]), its news (what happened and what's been seen) and
/// today's / this week's meals. What [PetSync] moves between the device
/// and the account.
class PetSnapshot {
  final String? name;
  final String? color;
  final String? accessory;
  final String? outfit;
  final PetState state;

  /// The inbox's moments, as `PetNotice.toJson()` maps.
  final List<Map<String, dynamic>> events;
  final List<String> seen;

  /// The day today's quiz was finished (yyyy-mm-dd) and the ISO week of
  /// the last feast ("2026-42").
  final String? mealDoneOn;
  final String? feastDoneWeek;

  /// When this copy last changed (on whichever device changed it).
  final DateTime updatedAt;

  const PetSnapshot({
    required this.state,
    required this.updatedAt,
    this.name,
    this.color,
    this.accessory,
    this.outfit,
    this.events = const [],
    this.seen = const [],
    this.mealDoneOn,
    this.feastDoneWeek,
  });

  /// A brand-new egg, nothing else.
  factory PetSnapshot.fresh(DateTime now) =>
      PetSnapshot(state: PetState.newborn(now), updatedAt: now);

  factory PetSnapshot.fromRow(Map<String, dynamic> row) => PetSnapshot(
        name: row['name'] as String?,
        color: row['color'] as String?,
        accessory: row['accessory'] as String?,
        outfit: row['outfit'] as String?,
        state:
            PetState.fromJson(Map<String, dynamic>.from(row['state'] as Map)),
        events: [
          for (final e in (row['events'] as List?) ?? const [])
            Map<String, dynamic>.from(e as Map),
        ],
        seen: ((row['seen'] as List?) ?? const []).cast<String>(),
        mealDoneOn: row['meal_done_on'] as String?,
        feastDoneWeek: row['feast_done_week'] as String?,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );

  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'name': name,
        'color': color,
        'accessory': accessory,
        // Only once one's been chosen, so a server without the column yet
        // (see the 20261020_pet_outfit migration) still takes the rest.
        if (outfit != null) 'outfit': outfit,
        'state': state.toJson(),
        'events': events,
        'seen': seen,
        'meal_done_on': mealDoneOn,
        'feast_done_week': feastDoneWeek,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

/// Where the user's pet is kept in their account.
abstract class PetRemote {
  /// The user's pet, or null when they don't have one saved yet.
  Future<PetSnapshot?> load(String userId);

  Future<void> save(String userId, PetSnapshot pet);

  /// The premium things the user has bought for it (`BlobAccessory.itemId`,
  /// `BlobOutfit.itemId`). Read-only: only the server grants them.
  Future<Set<String>> ownedItems(String userId);
}

/// [PetRemote] on Supabase: one row per user in `ingatanku.pets`, and one
/// per thing bought in `ingatanku.pet_items`.
class SupabasePetRemote implements PetRemote {
  final SupabaseService service;
  SupabasePetRemote(this.service);

  @override
  Future<PetSnapshot?> load(String userId) async {
    final row = await service.db
        .from(AppConstants.tPets)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : PetSnapshot.fromRow(row);
  }

  @override
  Future<void> save(String userId, PetSnapshot pet) => service.db
      .from(AppConstants.tPets)
      .upsert(pet.toRow(userId), onConflict: 'user_id');

  @override
  Future<Set<String>> ownedItems(String userId) async {
    final rows = await service.db
        .from(AppConstants.tPetItems)
        .select('item')
        .eq('user_id', userId);
    return {for (final row in rows) row['item'] as String};
  }
}
