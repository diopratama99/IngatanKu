import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/companion/data/pet_inbox.dart';
import 'package:ingatanku/features/companion/data/pet_remote.dart';
import 'package:ingatanku/features/companion/data/pet_store.dart';
import 'package:ingatanku/features/companion/data/pet_sync.dart';
import 'package:ingatanku/features/companion/domain/companion_style.dart';
import 'package:ingatanku/features/companion/domain/pet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The account side, in memory.
class _Accounts implements PetRemote {
  final pets = <String, PetSnapshot>{};
  final items = <String, Set<String>>{};
  bool offline = false;
  int saves = 0;

  @override
  Future<PetSnapshot?> load(String userId) async {
    if (offline) throw Exception('offline');
    return pets[userId];
  }

  @override
  Future<void> save(String userId, PetSnapshot pet) async {
    if (offline) throw Exception('offline');
    saves++;
    // Through the row format, as the server would see it.
    pets[userId] = PetSnapshot.fromRow(
        jsonDecode(jsonEncode(pet.toRow(userId))) as Map<String, dynamic>);
  }

  @override
  Future<Set<String>> ownedItems(String userId) async {
    if (offline) throw Exception('offline');
    return {...?items[userId]};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime(2026, 10, 16, 9);
  var now = t0;

  late _Accounts accounts;
  late PetStore store;
  late PetInbox inbox;
  late PetSync sync;
  late StreamController<String?> users;

  PetState grownPet(int growth) => PetState(
        bornAt: t0.subtract(const Duration(days: 9)),
        hatchedAt: t0.subtract(const Duration(days: 8)),
        fullness: 60,
        fullnessUpdatedAt: t0,
        happiness: 70,
        happinessUpdatedAt: t0,
        growth: growth,
      );

  /// A device with [prefs] already on it, signed in as [user].
  Future<void> device(Map<String, Object> prefs, {String? user}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    store = PetStore(sp, clock: () => now);
    inbox = PetInbox(sp, store, clock: () => now);
    users = StreamController<String?>();
    sync = PetSync(sp, store, inbox, accounts,
        clock: () => now, debounce: const Duration(hours: 1));
    sync.start(user, users.stream);
    await pumpEventQueue();
  }

  setUp(() {
    accounts = _Accounts();
    now = t0;
  });

  tearDown(() {
    sync.dispose();
    users.close();
  });

  test('a pet from before accounts goes up the first time', () async {
    await device({
      'pet.state': jsonEncode(grownPet(120).toJson()),
      'pet.name': 'Mochi',
      'pet.color': 'taro',
    }, user: 'ana');
    final saved = accounts.pets['ana']!;
    expect(saved.name, 'Mochi');
    expect(saved.color, 'taro');
    expect(saved.state.growth, 120);
  });

  test('a new phone gets the pet from the account, quietly', () async {
    accounts.pets['ana'] = PetSnapshot(
      state: grownPet(300),
      name: 'Mochi',
      accessory: 'crown',
      events: [
        {'id': 'hatched', 'kind': 'hatched', 'at': t0.millisecondsSinceEpoch},
      ],
      mealDoneOn: PetState.dayKey(t0),
      updatedAt: t0,
    );
    await device({}, user: 'ana');
    expect(store.state.growth, 300);
    expect(store.customName, 'Mochi');
    expect(store.accessory, BlobAccessory.crown);
    expect(inbox.mealDoneOn(t0), isTrue);
    // It hatched on the other phone, not here: no second "hatched".
    expect(inbox.notices(t0).where((n) => n.kind == PetNoticeKind.hatched),
        hasLength(1));
    expect(accounts.saves, 0);
  });

  test('another account never takes over the pet on this phone', () async {
    await device({
      'pet.state': jsonEncode(grownPet(200).toJson()),
      'pet.name': 'Mochi',
      'pet.owner': 'ana',
    }, user: 'ana');
    // Ana signs out, Budi signs in: he gets an egg of his own.
    users.add(null);
    await pumpEventQueue();
    users.add('budi');
    await pumpEventQueue();
    expect(store.state.stage, PetStage.egg);
    expect(store.customName, isNull);
    expect(accounts.pets['budi']!.state.stage, PetStage.egg);
    expect(accounts.pets['ana']!.state.growth, 200);
    // And Ana gets hers back.
    users.add('ana');
    await pumpEventQueue();
    expect(store.state.growth, 200);
    expect(store.customName, 'Mochi');
  });

  test('offline: nothing goes up until the account has been seen', () async {
    accounts.pets['ana'] = PetSnapshot(state: grownPet(500), updatedAt: t0);
    accounts.offline = true;
    await device({
      'pet.state': jsonEncode(grownPet(20).toJson()),
      'pet.owner': 'ana',
    }, user: 'ana');
    store.pet();
    await sync.flush();
    expect(accounts.pets['ana']!.state.growth, 500);
    // Back online: the account's (newer) pet comes down.
    accounts.offline = false;
    sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(store.state.growth, 500);
  });

  test('changes go up; the newer copy wins', () async {
    await device({}, user: 'ana');
    now = t0.add(const Duration(minutes: 5));
    store.snack(noteId: 'n1', food: FoodKind.cookie);
    await sync.flush();
    expect(accounts.pets['ana']!.state.hasEaten('n1'), isTrue);

    // Fed on another phone later: that copy wins over this older one.
    final elsewhere = accounts.pets['ana']!;
    accounts.pets['ana'] = PetSnapshot(
      state: elsewhere.state
          .snack(noteId: 'n2', food: FoodKind.chips, now: now)
          .state,
      updatedAt: t0.add(const Duration(hours: 1)),
    );
    users.add(null);
    await pumpEventQueue();
    users.add('ana');
    await pumpEventQueue();
    expect(store.state.hasEaten('n2'), isTrue);
  });

  test('what was bought for it comes down, and stays with its account',
      () async {
    accounts.items['ana'] = {'accessory.chefHat', 'outfit.dino'};
    accounts.pets['ana'] = PetSnapshot(
      state: grownPet(300),
      accessory: 'chefHat',
      outfit: 'dino',
      updatedAt: t0,
    );
    await device({}, user: 'ana');
    expect(store.owned, {'accessory.chefHat', 'outfit.dino'});
    expect(store.accessory, BlobAccessory.chefHat);
    expect(store.outfit, BlobOutfit.dino);
    // Only ever comes down: nothing to send.
    expect(accounts.saves, 0);

    // Bought on another phone (or given): here when the app comes back.
    accounts.items['ana']!.add('outfit.batik');
    sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(store.canWearOutfit(BlobOutfit.batik), isTrue);
    // Offline, it keeps what it had.
    accounts.offline = true;
    sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(store.owned, hasLength(3));
    accounts.offline = false;

    // Budi doesn't get Ana's things.
    users.add('budi');
    await pumpEventQueue();
    expect(store.owned, isEmpty);
    expect(store.outfit, BlobOutfit.none);
    // And Ana's are hers again, as she left them.
    users.add('ana');
    await pumpEventQueue();
    expect(store.outfit, BlobOutfit.dino);
    expect(accounts.saves, 1); // Budi's egg
  });
}
