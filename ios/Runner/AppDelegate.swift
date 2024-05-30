// import UIKit
// import Flutter
//
// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }

import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCbAq1UtzoUlVx4djUkuETaRur7X4TEel4")

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let screenshotChannel = FlutterMethodChannel(name: "com.example/screenshot",
                                                     binaryMessenger: controller.binaryMessenger)
        screenshotChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          if call.method == "captureScreenshot" {
            guard let args = call.arguments as? [String: CGFloat],
                  let x = args["x"],
                  let y = args["y"],
                  let width = args["width"],
                  let height = args["height"] else {
              result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
              return
            }
            self.captureScreenshot(x: x, y: y, width: width, height: height, result: result)
          } else {
            result(FlutterMethodNotImplemented)
          }
        })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
   private func captureScreenshot(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, result: FlutterResult) {
       guard let rootViewController = window?.rootViewController else {
         result(FlutterError(code: "UNAVAILABLE", message: "Root view controller unavailable", details: nil))
         return
       }

       let renderer = UIGraphicsImageRenderer(bounds: CGRect(x: x, y: y, width: width, height: height))
       let image = renderer.image { ctx in
         rootViewController.view.drawHierarchy(in: rootViewController.view.bounds, afterScreenUpdates: true)
       }
       if let imageData = image.pngData() {
         result(FlutterStandardTypedData(bytes: imageData))
       } else {
         result(FlutterError(code: "UNAVAILABLE", message: "Failed to capture screenshot", details: nil))
       }
     }
}
