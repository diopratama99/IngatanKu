import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/companion/data/pet_inbox.dart';
import '../../features/companion/data/pet_store.dart';
import '../../features/companion/domain/companion_style.dart';
import '../../features/companion/domain/pet_state.dart';
import '../../features/companion/presentation/pet_labels.dart';
import '../../features/companion/presentation/widgets/blob_mascot.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_settings_service.dart';

/// Bridge between the app and the home-screen widget (`PetWidget.kt`):
/// the pet, looking the way it feels, with one button for what to do
/// about it.
///
///   1. Writes what the widget needs to know — hatched yet, the daily
///      quiz open yet, the day it last ate it, its meal streak — and every
///      line it might say, in the app's language. The widget picks the
///      right one for the time (hungry from midnight, sad in the evening)
///      on its own.
///   2. Draws a still of each face (egg, hungry, sad, happy) whenever the
///      pet's look changes, for the widget to show.
///   3. Hands on the taps (`ingatanku://quiz`, `ingatanku://home`), on
///      cold start and while running.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// Class name (Kotlin) of the AppWidgetProvider — must match exactly.
  static const String _androidWidgetName = 'PetWidget';

  /// iOS app group ID, used by WidgetKit to share `UserDefaults`. Harmless on
  /// Android — the package treats it as a no-op there.
  static const String _appGroupId = 'group.com.temanlabs.ingatanku';

  static const _faces = ['egg', 'hungry', 'sad', 'happy'];

  PetStore? _store;
  PetInbox? _inbox;
  Timer? _soon;

  /// What was last written; lets us skip redraws when nothing changed.
  String? _lastPush;

  Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Keeps the widget in step with the pet (and the app's language).
  void watch(PetStore store, PetInbox inbox) {
    _store = store;
    _inbox = inbox;
    store.addListener(_schedule);
    inbox.addListener(_schedule);
    AppSettingsService.instance.addListener(_schedule);
    _schedule();
  }

  // A plain timer, not an AppTimer: leaving the app right after a meal
  // should still update the widget.
  void _schedule() {
    _soon?.cancel();
    _soon = Timer(const Duration(milliseconds: 800), _push);
  }

  Future<void> _push() async {
    final store = _store, inbox = _inbox;
    if (store == null || inbox == null) return;
    final l10n =
        lookupAppLocalizations(AppSettingsService.instance.resolvedLocale);
    final data = petWidgetData(store, inbox, l10n, DateTime.now());
    final fingerprint = jsonEncode(data);
    if (fingerprint == _lastPush) return;
    try {
      final drawn = await HomeWidget.getWidgetData<String>('pet.look');
      if (drawn != data['pet.look']) await _drawFaces(store);
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
      _lastPush = fingerprint;
    } catch (e, st) {
      debugPrint('[HomeWidget] push failed: $e\n$st');
    }
  }

  Future<void> _drawFaces(PetStore store) async {
    final dir = await getApplicationSupportDirectory();
    for (final face in _faces) {
      final png = await _still(petStill(store, face), size: 120);
      if (png == null) continue;
      final file = File('${dir.path}/home_widget/pet_$face.png');
      await file.create(recursive: true);
      await file.writeAsBytes(png);
      await HomeWidget.saveWidgetData<String>('pet.img.$face', file.path);
    }
  }

  /// Returns the URI that launched the app via a widget tap on cold start,
  /// or `null` if the launch was unrelated to the widget.
  Future<Uri?> consumeColdStartUri() {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  /// Stream of URIs emitted whenever the user taps a clickable region inside
  /// the widget while the app is already running.
  Stream<Uri?> get tapStream => HomeWidget.widgetClicked;
}

/// Everything the widget reads, as strings. The lines are keyed by what
/// `PetWidget.kt` calls the moments: egg, locked (no daily quiz yet),
/// ready, late (still unfed in the evening) and full.
@visibleForTesting
Map<String, String> petWidgetData(
  PetStore store,
  PetInbox inbox,
  AppLocalizations l10n,
  DateTime now,
) {
  final pet = store.state;
  final name = l10n.petName(store);
  final lastFed = pet.lastMealAt ?? pet.lastFedAt;
  final streak = pet.careStreakAt(now);
  return {
    'pet.hatched': pet.hatched ? '1' : '0',
    'pet.unlocked': inbox.mealsUnlocked ? '1' : '0',
    'pet.mealDay': inbox.mealDoneDay ?? '',
    // The streak lives on while it was fed today or yesterday.
    'pet.streakDay': lastFed == null ? '' : PetState.dayKey(lastFed.toLocal()),
    'pet.look': [
      store.color.name,
      store.accessory.name,
      store.outfit.name,
      _grownStage(pet).name,
    ].join('|'),
    'pet.t.eggTitle': l10n.widgetEggTitle,
    'pet.t.eggBody': l10n.widgetEggBody(name),
    'pet.t.lockedTitle': l10n.widgetLockedTitle(name),
    'pet.t.lockedBody': l10n.widgetLockedBody,
    'pet.t.readyTitle': l10n.widgetReadyTitle(name),
    'pet.t.readyBody': l10n.widgetReadyBody,
    'pet.t.lateTitle': l10n.widgetLateTitle(name),
    'pet.t.lateBody': l10n.widgetLateBody,
    'pet.t.fullTitle': l10n.widgetFullTitle(name),
    'pet.t.fullBody': l10n.widgetFullBody,
    'pet.t.feed': l10n.widgetFeed,
    'pet.t.save': l10n.widgetSave,
    'pet.t.streak': streak > 0 ? l10n.widgetStreak(streak) : '',
  };
}

/// The hatched faces are drawn ahead of hatching too, as a baby.
PetStage _grownStage(PetState pet) =>
    pet.hatched ? pet.stage : PetStage.baby;

/// The pet as the widget shows it for [face], still, filling a square the
/// way [PetHost] does (by its body, not its jumping room).
@visibleForTesting
Widget petStill(PetStore store, String face) {
  final stage = face == 'egg' ? PetStage.egg : _grownStage(store.state);
  final (mood, expression) = switch (face) {
    'hungry' => (CompanionMood.hungry, BlobExpression.hungry),
    'sad' => (CompanionMood.lonely, BlobExpression.sad),
    'happy' => (CompanionMood.happy, null),
    _ => (CompanionMood.content, null),
  };
  return LayoutBuilder(builder: (context, box) {
    final side = box.biggest.shortestSide;
    final body =
        stage == PetStage.egg ? 0.84 * stage.scale : 0.74 * stage.scale;
    return SizedBox.square(
      dimension: side,
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: BlobMascot(
          size: side * 0.72 / body,
          color: store.color,
          accessory: store.accessory,
          outfit: store.outfit,
          stage: stage,
          mood: mood,
          expression: expression,
          interactive: false,
          animate: false,
        ),
      ),
    );
  });
}

/// Draws [child] off screen into a [size]-point square PNG, then takes
/// the tree down again (nothing is left running).
Future<Uint8List?> _still(Widget child,
    {required double size, double pixelRatio = 3}) async {
  final view = ui.PlatformDispatcher.instance.implicitView;
  if (view == null) return null;
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(child: boundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(Size.square(size)),
    ),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final focus = FocusManager();
  final build = BuildOwner(focusManager: focus);
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  ).attachToRenderTree(build);
  try {
    build.buildScope(root);
    build.finalizeTree();
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  } finally {
    RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
        .attachToRenderTree(build, root);
    build.finalizeTree();
    focus.dispose();
  }
}
