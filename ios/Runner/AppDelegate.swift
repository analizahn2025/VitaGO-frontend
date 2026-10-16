// Source: Google Maps Platform Code Assist
import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.addInternalUsageAttributionID("gmp_git_agentskills_v1")
    if let mapsApiKey = Bundle.main.object(
      forInfoDictionaryKey: "GoogleMapsApiKey"
    ) as? String,
      !mapsApiKey.isEmpty,
      !mapsApiKey.hasPrefix("$(")
    {
      GMSServices.provideAPIKey(mapsApiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
