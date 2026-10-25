import 'package:flutter/widgets.dart';

/// Global navigator key so non-widget code (e.g. [ApiClient]) can navigate
/// without a BuildContext — used to bounce the user to login when the backend
/// reports the session is no longer valid (401).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
