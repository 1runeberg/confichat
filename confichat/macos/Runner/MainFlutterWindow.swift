import Cocoa
import FlutterMacOS
import StoreKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "io.confichat/storefront",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "countryCode" else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let countryCode: String?
        if #available(macOS 10.15, *) {
          countryCode = SKPaymentQueue.default().storefront?.countryCode
        } else {
          countryCode = nil
        }
        DispatchQueue.main.async { result(countryCode) }
      }
    }

    super.awakeFromNib()
  }
}
