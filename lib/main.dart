import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/supabase_client.dart';
import 'core/services/app_pause.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/share_intent_service.dart';
import 'core/services/sound_service.dart';
import 'features/companion/data/pet_inbox.dart';
import 'features/companion/data/pet_store.dart';
import 'features/companion/presentation/widgets/food_painter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // AppSettingsService bootstraps SharedPreferences once and exposes
  // the resolved locale + theme to MaterialApp on first frame. Has to
  // run BEFORE initDependencies() because the DI container expects the
  // singleton to already exist.
  await AppSettingsService.init();
  await SupabaseService.init();
  await initDependencies();
  // These don't depend on each other.
  // The pet, its room and its sounds hold still while the app is away.
  AppPause.instance.init();
  await Future.wait([
    ConnectivityService.instance.init(),
    ShareIntentService.instance.init(),
    HomeWidgetService.instance.init(),
    SoundService.instance.init(),
  ]);

  runApp(const IngatanKuApp());

  // The home-screen widget follows the pet from here on.
  HomeWidgetService.instance.watch(sl<PetStore>(), sl<PetInbox>());

  // Not needed for the first frame: the onigiri picture (drawn plainly
  // until it's in). Reminders set up their time zones themselves the first
  // time one is scheduled (NotificationService.init).
  unawaited(FoodArt.load());
}
