import Flutter
import UIKit
import UserNotifications
import MessageUI

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let documentComposer = DocumentComposer()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DocumentComposer") {
      documentComposer.register(registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceWorkloadBridge") {
      let channel = FlutterMethodChannel(name: "maintainiac/device_capabilities", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "readRuntimeCapabilities" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let info = ProcessInfo.processInfo
        let thermal: String
        switch info.thermalState {
        case .nominal: thermal = "nominal"
        case .fair: thermal = "fair"
        case .serious: thermal = "serious"
        case .critical: thermal = "critical"
        @unknown default: thermal = "unknown"
        }
        result([
          "physicalRamMb": Int(info.physicalMemory / 1_048_576),
          "powerSaving": info.isLowPowerModeEnabled,
          "thermalState": thermal
        ])
      }
    }
  }
}


private final class DocumentComposer: NSObject, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
  private var pending: FlutterResult?

  func register(_ messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "maintainiac/document_compose", binaryMessenger: messenger).setMethodCallHandler { [weak self] call, result in
      guard call.method == "compose" else { result(FlutterMethodNotImplemented); return }
      guard let self = self, self.pending == nil,
            let args = call.arguments as? [String: Any],
            let data = (args["bytes"] as? FlutterStandardTypedData)?.data,
            data.starts(with: Data("%PDF-".utf8)),
            let recipient = args["recipient"] as? String, !recipient.isEmpty,
            let method = args["method"] as? String else {
        result(FlutterError(code: "invalid_document", message: "A valid document and recipient are required.", details: nil)); return
      }
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      guard var presenter = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else {
        result(FlutterError(code: "composer_unavailable", message: "The document screen is not available.", details: nil)); return
      }
      while let presented = presenter.presentedViewController { presenter = presented }
      let name = args["name"] as? String ?? "Estimate.pdf"
      if method == "email" && MFMailComposeViewController.canSendMail() {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = self
        controller.setToRecipients([recipient])
        controller.setSubject(args["subject"] as? String ?? "Estimate")
        controller.setMessageBody(args["text"] as? String ?? "", isHTML: false)
        controller.addAttachmentData(data, mimeType: "application/pdf", fileName: name)
        self.pending = result
        presenter.present(controller, animated: true)
      } else if method == "textMessage" && MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments() && MFMessageComposeViewController.isSupportedAttachmentUTI("com.adobe.pdf") {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = self
        controller.recipients = [recipient]
        controller.body = args["text"] as? String
        guard controller.addAttachmentData(data, typeIdentifier: "com.adobe.pdf", filename: name) else {
          result(FlutterError(code: "attachment_unavailable", message: "Messages cannot attach this PDF. Choose Share PDF or email.", details: nil)); return
        }
        self.pending = result
        presenter.present(controller, animated: true)
      } else {
        result(FlutterError(code: "composer_unavailable", message: "This device cannot compose that message with a PDF. Choose Share PDF or save and attach the document.", details: nil))
      }
    }
  }

  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true)
    let callback = pending; pending = nil
    callback?(result == .cancelled ? "cancelled" : "unconfirmed")
  }

  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    controller.dismiss(animated: true)
    let callback = pending; pending = nil
    callback?(result == .cancelled ? "cancelled" : "unconfirmed")
  }
}
