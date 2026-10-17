import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  // Required before any plugin channel is touched. Wallet load and the audio
  // engines both need the binding up before the first frame.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JkReadNLearnApp());
}
