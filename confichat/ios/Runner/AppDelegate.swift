import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let hingeStreamHandler = HingeStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    let storefrontChannel = FlutterMethodChannel(
      name: "io.confichat/storefront",
      binaryMessenger: messenger
    )
    storefrontChannel.setMethodCallHandler { call, result in
      guard call.method == "countryCode" else {
        result(FlutterMethodNotImplemented)
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        let countryCode = SKPaymentQueue.default().storefront?.countryCode
        DispatchQueue.main.async { result(countryCode) }
      }
    }

    let hingeChannel = FlutterEventChannel(name: "io.confichat/hinge", binaryMessenger: messenger)
    hingeChannel.setStreamHandler(hingeStreamHandler)
  }

  // Folded Duo is portrait only. Otherwise allow everything and let Info.plist narrow it per device
  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    return hingeStreamHandler.isClosed ? .portrait : .all
  }
}

// Streams the device hinge status to Dart (nil on devices without a hinge)
class HingeStreamHandler: NSObject, FlutterStreamHandler {
  private var interaction: UIInteraction?
  private(set) var isClosed = false

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    events(nil)

    guard #available(iOS 27.1, *) else { return nil }

    DispatchQueue.main.async { [weak self] in
      self?.attach(events)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let interaction {
      interaction.view?.removeInteraction(interaction)
    }

    interaction = nil
    return nil
  }

  @available(iOS 27.1, *)
  private func attach(_ events: @escaping FlutterEventSink) {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }

    guard let view = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController?.view
    else { return }

    let hingeInteraction = UIHingeInteraction { [weak self, weak view] _, update in
      self?.updateOrientationLock(closed: update.hinge?.status == .closed, view: view)
      events(update.hinge.map { HingeStreamHandler.name(for: $0.status) })
    }
    view.addInteraction(hingeInteraction)
    interaction = hingeInteraction
  }

  @available(iOS 27.1, *)
  private func updateOrientationLock(closed: Bool, view: UIView?) {
    guard closed != isClosed else { return }

    isClosed = closed

    guard let window = view?.window else { return }

    window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

    // Unfolding clears the folded portrait request so the inner display can rotate
    window.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: closed ? .portrait : .all))
  }

  @available(iOS 27.1, *)
  private static func name(for status: UIHinge.Status) -> String {
    switch status {
    case .closed: return "closed"
    case .partiallyOpen: return "partiallyOpen"
    case .fullyOpen: return "fullyOpen"
    default: return "unknown"
    }
  }
}
