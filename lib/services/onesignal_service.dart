import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String _appId = '4664291b-ed36-4a48-858f-dac4cde019f7';

  static Future<void> initialize() async {
    // Enable verbose OneSignal logging to debug issues if needed.
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize OneSignal
    OneSignal.initialize(_appId);

    // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. 
    // We recommend removing the following code and instead using an In-App Message to prompt for notification permission
    OneSignal.Notifications.requestPermission(true);
  }
}
