import '../../../l10n/generated/app_localizations.dart';
import '../data/pet_store.dart';
import '../domain/companion_style.dart';

/// Localized names for the pet's enums, shared by Beranda and the
/// wardrobe sheet.
extension PetLabels on AppLocalizations {
  String petName(PetStore store) => store.customName ?? petDefaultName;

  String stageLabel(PetStage s) => switch (s) {
        PetStage.egg => petStageEgg,
        PetStage.baby => petStageBaby,
        PetStage.kid => petStageKid,
        PetStage.teen => petStageTeen,
        PetStage.adult => petStageAdult,
        PetStage.sage => petStageSage,
      };

  String foodLabel(FoodKind f) => switch (f) {
        FoodKind.bento => petFoodBento,
        FoodKind.sandwich => petFoodSandwich,
        FoodKind.onigiri => petFoodOnigiri,
        FoodKind.donut => petFoodDonut,
        FoodKind.cookie => petFoodCookie,
        FoodKind.chips => petFoodChips,
      };

  String colorLabel(BlobColor c) => switch (c) {
        BlobColor.matcha => petColorMatcha,
        BlobColor.peach => petColorPeach,
        BlobColor.sky => petColorSky,
        BlobColor.taro => petColorTaro,
        BlobColor.honey => petColorHoney,
        BlobColor.mocha => petColorMocha,
        BlobColor.mochi => petColorMochi,
      };

  String accessoryLabel(BlobAccessory a) => switch (a) {
        BlobAccessory.none => petAccessoryNone,
        BlobAccessory.sprout => petAccessorySprout,
        BlobAccessory.bow => petAccessoryBow,
        BlobAccessory.glasses => petAccessoryGlasses,
        BlobAccessory.scarf => petAccessoryScarf,
        BlobAccessory.beanie => petAccessoryBeanie,
        BlobAccessory.headphones => petAccessoryHeadphones,
        BlobAccessory.crown => petAccessoryCrown,
        BlobAccessory.chefHat => petAccessoryChefHat,
        BlobAccessory.partyHat => petAccessoryPartyHat,
        BlobAccessory.catEars => petAccessoryCatEars,
        BlobAccessory.flower => petAccessoryFlower,
        BlobAccessory.peci => petAccessoryPeci,
        BlobAccessory.witchHat => petAccessoryWitchHat,
        BlobAccessory.santaHat => petAccessorySantaHat,
      };

  String outfitLabel(BlobOutfit o) => switch (o) {
        BlobOutfit.none => petOutfitNone,
        BlobOutfit.hoodie => petOutfitHoodie,
        BlobOutfit.stripedTee => petOutfitStripedTee,
        BlobOutfit.overalls => petOutfitOveralls,
        BlobOutfit.sweater => petOutfitSweater,
        BlobOutfit.batik => petOutfitBatik,
        BlobOutfit.dino => petOutfitDino,
        BlobOutfit.frog => petOutfitFrog,
        BlobOutfit.bee => petOutfitBee,
        BlobOutfit.astronaut => petOutfitAstronaut,
        BlobOutfit.raincoat => petOutfitRaincoat,
        BlobOutfit.koko => petOutfitKoko,
        BlobOutfit.pumpkin => petOutfitPumpkin,
      };

  String outfitGroupLabel(OutfitGroup g) => switch (g) {
        OutfitGroup.everyday => petOutfitGroupEveryday,
        OutfitGroup.costume => petOutfitGroupCostume,
        OutfitGroup.seasonal => petOutfitGroupSeasonal,
      };
}
