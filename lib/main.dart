import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/network/supabase_client.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/share_intent_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await SupabaseService.init();
  await initDependencies();
  await NotificationService.instance.init();
  await ShareIntentService.instance.init();
  await HomeWidgetService.instance.init();

  runApp(const IngatanKuApp());
}
