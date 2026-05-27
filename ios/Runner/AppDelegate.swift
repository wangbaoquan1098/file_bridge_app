import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var systemSettingsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerSystemSettingsChannel(binaryMessenger: engineBridge.applicationRegistrar.messenger())
  }

  private func registerSystemSettingsChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "file_bridge/system_settings",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "openAppSettings" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        result(false)
        return
      }

      DispatchQueue.main.async {
        UIApplication.shared.open(url) { success in
          result(success)
        }
      }
    }
    systemSettingsChannel = channel
  }
}
