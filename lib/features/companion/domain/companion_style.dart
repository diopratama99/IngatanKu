import 'package:flutter/material.dart';

/// Body colour options for the pet. All free — colour is pure
/// self-expression, so it isn't gated behind growth.
///
/// [base] fills the body, [shade] is used for the rim / feet / outline.
enum BlobColor {
  matcha(Color(0xFFA3BE8C), Color(0xFF7E9A68)),
  peach(Color(0xFFF4B393), Color(0xFFD98E6C)),
  sky(Color(0xFF9CC3E0), Color(0xFF7299B8)),
  taro(Color(0xFFBBA5D8), Color(0xFF927BB3)),
  honey(Color(0xFFF2C76E), Color(0xFFCFA046)),
  mocha(Color(0xFFC09A7C), Color(0xFF977257)),
  mochi(Color(0xFFF1E9DC), Color(0xFFCDBFA8));

  final Color base;
  final Color shade;
  const BlobColor(this.base, this.shade);

  /// A pet that hasn't been given a colour is honey, like Bolubi in the
  /// logo.
  static BlobColor fromId(String? id) => BlobColor.values.firstWhere(
        (c) => c.name == id,
        orElse: () => BlobColor.honey,
      );
}

/// Life stages — this replaces the old level number. Growth points
/// only come from eating knowledge, so the pet literally grows with
/// what the user saves.
///
/// [scale] sizes the body relative to the adult; [eyeBoost] makes the
/// young ones extra big-eyed.
enum PetStage {
  egg(0, 0.7, 1.0),
  baby(0, 0.6, 1.25),
  kid(120, 0.72, 1.12),
  teen(360, 0.84, 1.04),
  adult(800, 0.94, 1.0),
  sage(1600, 1.0, 0.95);

  final int minGrowth;
  final double scale;
  final double eyeBoost;
  const PetStage(this.minGrowth, this.scale, this.eyeBoost);

  PetStage? get next =>
      index + 1 < PetStage.values.length ? PetStage.values[index + 1] : null;

  /// Stage for a hatched pet with [growth] points.
  static PetStage forGrowth(int growth) {
    var stage = PetStage.baby;
    for (final s in PetStage.values.skip(1)) {
      if (growth >= s.minGrowth) stage = s;
    }
    return stage;
  }

  /// 0..1 progress from this stage toward [next]; 1 at the last stage.
  double progress(int growth) {
    final n = next;
    if (n == null) return 1;
    final span = n.minGrowth - minGrowth;
    return ((growth - minGrowth) / span).clamp(0.0, 1.0);
  }
}

/// Wearables on its head (and the scarf and glasses). The free ones each
/// open at a life stage, so growing up has something visible to reward;
/// [premium] ones are bought one by one, in the boutique (what's been
/// bought comes from the account — `PetRemote.ownedItems`).
enum BlobAccessory {
  none(PetStage.baby),
  sprout(PetStage.baby),
  bow(PetStage.kid),
  glasses(PetStage.kid),
  scarf(PetStage.teen),
  beanie(PetStage.teen),
  headphones(PetStage.adult),
  crown(PetStage.sage),
  chefHat(PetStage.baby, premium: true),
  partyHat(PetStage.baby, premium: true),
  catEars(PetStage.baby, premium: true),
  flower(PetStage.baby, premium: true),
  peci(PetStage.baby, premium: true),
  witchHat(PetStage.baby, premium: true, seasonal: true),
  santaHat(PetStage.baby, premium: true, seasonal: true);

  final PetStage unlockStage;
  final bool premium;

  /// For a time of year (Halloween, Christmas…).
  final bool seasonal;
  const BlobAccessory(this.unlockStage,
      {this.premium = false, this.seasonal = false});

  /// Whether a free one has opened yet (a premium one is worn once it's
  /// bought — see `PetStore.canWearAccessory`).
  bool unlockedAt(PetStage stage) =>
      !premium && stage.index >= unlockStage.index;

  /// Sits on its head, so a hood or helmet ([BlobOutfit.coversHead]) hides
  /// it; glasses and a scarf don't.
  bool get onHead => this != none && this != glasses && this != scarf;

  /// What it's called when bought (`ingatanku.pet_items.item`).
  String get itemId => 'accessory.$name';

  static BlobAccessory fromId(String? id) => BlobAccessory.values.firstWhere(
        (a) => a.name == id,
        orElse: () => BlobAccessory.sprout,
      );
}

/// The wardrobe's outfits, in its sections.
enum OutfitGroup { everyday, costume, seasonal }

/// Clothes over its body, worn alongside an accessory. All but [none]
/// are [premium] (see [BlobAccessory]). A costume or coat with its hood
/// up, or a space helmet, [coversHead]: the head accessory comes off
/// while it's on (glasses stay).
enum BlobOutfit {
  none(OutfitGroup.everyday, premium: false),
  hoodie(OutfitGroup.everyday),
  stripedTee(OutfitGroup.everyday),
  overalls(OutfitGroup.everyday),
  sweater(OutfitGroup.everyday),
  batik(OutfitGroup.everyday),
  dino(OutfitGroup.costume, coversHead: true),
  frog(OutfitGroup.costume, coversHead: true),
  bee(OutfitGroup.costume, coversHead: true),
  astronaut(OutfitGroup.costume, coversHead: true),
  raincoat(OutfitGroup.seasonal, coversHead: true),
  koko(OutfitGroup.seasonal),
  pumpkin(OutfitGroup.seasonal, coversHead: true);

  final OutfitGroup group;
  final bool premium;
  final bool coversHead;
  const BlobOutfit(this.group, {this.premium = true, this.coversHead = false});

  /// What it's called when bought (`ingatanku.pet_items.item`).
  String get itemId => 'outfit.$name';

  static BlobOutfit fromId(String? id) => BlobOutfit.values.firstWhere(
        (o) => o.name == id,
        orElse: () => BlobOutfit.none,
      );
}

/// Knowledge as food. Long-form sources are a full meal, short-form
/// ones are snacks — so saving a deep-dive feeds the pet more than a
/// quick post.
/// The pet's food. Its meals come from quizzes — an [onigiri] for each
/// daily-quiz answer, a [bento] at the weekly feast — and every new note
/// is a snack ([fromSource]).
enum FoodKind {
  bento,
  sandwich,
  onigiri,
  donut,
  cookie,
  chips;

  /// The snack a note makes, by its `sourceType` (see
  /// `StringX.sourceFromUrl`).
  static FoodKind fromSource(String sourceType) => switch (sourceType) {
        'youtube' => FoodKind.donut,
        'article' => FoodKind.onigiri,
        'instagram' || 'facebook' => FoodKind.cookie,
        _ => FoodKind.chips,
      };

  /// The meal a quiz answer makes: an onigiri every day, a bento at the
  /// weekly [feast].
  static FoodKind meal({required bool feast}) =>
      feast ? FoodKind.bento : FoodKind.onigiri;
}

/// What the pet feels when nobody is interacting with it. Derived from
/// its vitals and the time of day.
enum CompanionMood { happy, content, hungry, lonely, sleepy }
