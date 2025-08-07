//
//  SharingManager.swift
//  ScheduleShare
//
//  Calendar sharing functionality
//

import Foundation
import UIKit
import MessageUI

class SharingManager: NSObject, ObservableObject {
    static let shared = SharingManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Share Calendar Events
    func shareCalendar(_ events: [CalendarEvent], method: SharingMethod, completion: @escaping (Result<Void, Error>) -> Void) {
        switch method {
        case .icsFile:
            shareAsICSFile(events, completion: completion)
        case .message:
            shareViaMessage(events, completion: completion)
        case .email:
            shareViaEmail(events, completion: completion)
        case .link:
            shareViaLink(events, completion: completion)
        }
    }
    
    // MARK: - ICS File Sharing
    private func shareAsICSFile(_ events: [CalendarEvent], completion: @escaping (Result<Void, Error>) -> Void) {
        let calendarManager = CalendarManager()
        let icsContent = calendarManager.exportCalendarEvents(events)
        
        let fileName = "ScheduleShare_Calendar.ics"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try icsContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            DispatchQueue.main.async {
                let shareText = "📅 Calendar Events (\(events.count) events)\n\nImport this .ics file into your calendar app to add all events!"
                let activityVC = UIActivityViewController(activityItems: [shareText, tempURL], applicationActivities: nil)
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    
                    // Ensure we're not already presenting something
                    if rootViewController.presentedViewController != nil {
                        rootViewController.dismiss(animated: true) {
                            self.presentActivityVC(activityVC, from: rootViewController)
                        }
                    } else {
                        self.presentActivityVC(activityVC, from: rootViewController)
                    }
                    
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func presentActivityVC(_ activityVC: UIActivityViewController, from rootViewController: UIViewController) {
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Set completion handler to ensure proper dismissal
        activityVC.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, error) in
            print("📤 Activity view controller completed: \(completed)")
            if let error = error {
                print("❌ Activity error: \(error.localizedDescription)")
            }
            
            // Ensure we're back to the main app
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    // Make sure we're not stuck in any presentation
                    if rootViewController.presentedViewController != nil {
                        rootViewController.dismiss(animated: true)
                    }
                }
            }
        }
        
        rootViewController.present(activityVC, animated: true)
    }
    
    // MARK: - Message Sharing
    private func shareViaMessage(_ events: [CalendarEvent], completion: @escaping (Result<Void, Error>) -> Void) {
        print("📱 Starting message share with \(events.count) events")
        
        if MFMessageComposeViewController.canSendText() {
            let messageBody = createTextSummary(events)
            
            DispatchQueue.main.async {
                let messageVC = MFMessageComposeViewController()
                messageVC.messageComposeDelegate = self
                messageVC.body = messageBody
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    
                    print("📱 Presenting message compose controller")
                    
                    // Ensure we're not already presenting something
                    if rootViewController.presentedViewController != nil {
                        print("📱 Dismissing existing presentation first")
                        rootViewController.dismiss(animated: true) {
                            self.presentMessageVC(messageVC, from: rootViewController)
                        }
                    } else {
                        self.presentMessageVC(messageVC, from: rootViewController)
                    }
                    
                    completion(.success(()))
                } else {
                    print("❌ Could not find root view controller")
                    completion(.failure(SharingError.exportFailed))
                }
            }
        } else {
            print("❌ Message compose not available")
            completion(.failure(SharingError.messageNotAvailable))
        }
    }
    
    private func presentMessageVC(_ messageVC: MFMessageComposeViewController, from rootViewController: UIViewController) {
        // For iPad
        if let popover = messageVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(messageVC, animated: true)
    }
    
    // MARK: - Email Sharing
    private func shareViaEmail(_ events: [CalendarEvent], completion: @escaping (Result<Void, Error>) -> Void) {
        print("📧 Starting email share with \(events.count) events")
        print("📧 Can send mail: \(MFMailComposeViewController.canSendMail())")
        
        // Check if we're on simulator
        #if targetEnvironment(simulator)
        print("📧 Running on iOS Simulator - mail may not work")
        #endif
        
        if MFMailComposeViewController.canSendMail() {
            let calendarManager = CalendarManager()
            let icsContent = calendarManager.exportCalendarEvents(events)
            let icsData = icsContent.data(using: .utf8)
            
            DispatchQueue.main.async {
                let mailVC = MFMailComposeViewController()
                mailVC.mailComposeDelegate = self
                mailVC.setSubject("Shared Calendar - ScheduleShare")
                mailVC.setMessageBody(self.createEmailBody(events), isHTML: true)
                
                if let icsData = icsData {
                    mailVC.addAttachmentData(icsData, mimeType: "text/calendar", fileName: "calendar.ics")
                    print("📧 Added ICS attachment")
                }
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    
                    print("📧 Found root view controller, presenting mail compose controller")
                    print("📧 Root view controller: \(type(of: rootViewController))")
                    print("📧 Has presented view controller: \(rootViewController.presentedViewController != nil)")
                    
                    // Ensure we're not already presenting something
                    if rootViewController.presentedViewController != nil {
                        print("📧 Dismissing existing presentation first")
                        rootViewController.dismiss(animated: true) {
                            print("📧 Existing presentation dismissed, now presenting mail")
                            self.presentMailVC(mailVC, from: rootViewController)
                        }
                    } else {
                        print("📧 No existing presentation, presenting mail directly")
                        self.presentMailVC(mailVC, from: rootViewController)
                    }
                    
                    completion(.success(()))
                } else {
                    print("❌ Could not find root view controller")
                    print("❌ Window scenes: \(UIApplication.shared.connectedScenes.count)")
                    completion(.failure(SharingError.exportFailed))
                }
            }
        } else {
            print("❌ Mail compose not available")
            completion(.failure(SharingError.emailNotAvailable))
        }
    }
    
    private func presentMailVC(_ mailVC: MFMailComposeViewController, from rootViewController: UIViewController) {
        print("📧 presentMailVC called")
        
        // For iPad
        if let popover = mailVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
            print("📧 Set up popover for iPad")
        }
        
        print("📧 About to present mail compose controller")
        print("📧 Root view controller bounds: \(rootViewController.view.bounds)")
        print("📧 Mail VC delegate: \(mailVC.mailComposeDelegate != nil)")
        
        // Add a small delay to ensure proper presentation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            rootViewController.present(mailVC, animated: true) {
                print("📧 Mail compose controller presentation completed")
                
                // Check if it's actually presented
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if rootViewController.presentedViewController == mailVC {
                        print("✅ Mail compose controller is successfully presented")
                    } else {
                        print("❌ Mail compose controller is not presented")
                        print("📧 Current presented view controller: \(rootViewController.presentedViewController?.description ?? "nil")")
                    }
                }
            }
        }
    }
    
    // MARK: - Link Sharing
    private func shareViaLink(_ events: [CalendarEvent], completion: @escaping (Result<Void, Error>) -> Void) {
        // Create a comprehensive sharing message with event details
        let shareText = createShareableText(events)
        let shareURL = createShareableURL(events)
        
        var activityItems: [Any] = [shareText]
        
        // Add URL if we have one
        if let url = shareURL {
            activityItems.append(url)
        }
        
        // Add ICS file for calendar import
        if let icsData = createICSData(events) {
            activityItems.append(icsData)
        }
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                // Ensure we're not already presenting something
                if rootViewController.presentedViewController != nil {
                    rootViewController.dismiss(animated: true) {
                        self.presentActivityVC(activityVC, from: rootViewController)
                    }
                } else {
                    self.presentActivityVC(activityVC, from: rootViewController)
                }
                
                completion(.success(()))
            }
        }
    }
    
    private func createShareableText(_ events: [CalendarEvent]) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var text = "📅 My Calendar Events (\(events.count) events)\n\n"
        
        for event in events {
            text += "📍 \(event.title)\n"
            text += "🕐 \(formatter.string(from: event.startDate))\n"
            if let location = event.location {
                text += "📍 \(location)\n"
            }
            text += "\n"
        }
        
        text += "📱 Shared via ScheduleShare\n"
        text += "💡 You can import the attached .ics file into your calendar app!"
        
        return text
    }
    
    private func createShareableURL(_ events: [CalendarEvent]) -> URL? {
        // Create a Google Calendar link for the first event (as an example)
        guard let firstEvent = events.first else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let startDate = formatter.string(from: firstEvent.startDate)
        let endDate = formatter.string(from: firstEvent.endDate)
        
        var urlString = "https://calendar.google.com/calendar/render?"
        urlString += "action=TEMPLATE"
        urlString += "&text=\(firstEvent.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        urlString += "&dates=\(startDate)/\(endDate)"
        
        if let location = firstEvent.location {
            urlString += "&location=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        return URL(string: urlString)
    }
    
    private func createICSData(_ events: [CalendarEvent]) -> Data? {
        let calendarManager = CalendarManager()
        let icsContent = calendarManager.exportCalendarEvents(events)
        return icsContent.data(using: .utf8)
    }
    
    // MARK: - Helper Methods
    private func createTextSummary(_ events: [CalendarEvent]) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var summary = "📅 Shared Calendar Events:\n\n"
        
        for event in events {
            summary += "📍 \(event.title)\n"
            summary += "🕐 \(formatter.string(from: event.startDate))\n"
            if let location = event.location {
                summary += "📍 \(location)\n"
            }
            summary += "\n"
        }
        
        summary += "Shared via ScheduleShare 📱"
        return summary
    }
    
    private func createEmailBody(_ events: [CalendarEvent]) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var html = """
        <html>
        <body>
        <h2>📅 Shared Calendar Events</h2>
        <p>I'm sharing my calendar events with you using ScheduleShare!</p>
        <table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse;">
        <tr style="background-color: #f0f0f0;">
        <th>Event</th>
        <th>Date & Time</th>
        <th>Location</th>
        </tr>
        """
        
        for event in events {
            html += """
            <tr>
            <td><strong>\(event.title)</strong></td>
            <td>\(formatter.string(from: event.startDate))</td>
            <td>\(event.location ?? "No location")</td>
            </tr>
            """
        }
        
        html += """
        </table>
        <p><em>You can import the attached .ics file into your calendar app to add these events.</em></p>
        <p>Best regards,<br>ScheduleShare 📱</p>
        </body>
        </html>
        """
        
        return html
    }
}

// MARK: - Message Compose Delegate
extension SharingManager: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        print("📱 Message compose finished with result: \(result.rawValue)")
        
        // Dismiss the message compose controller
        controller.dismiss(animated: true) {
            // Add a small delay to ensure proper dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    // Make sure we're not stuck in any presentation
                    if rootViewController.presentedViewController != nil {
                        rootViewController.dismiss(animated: true) {
                            print("✅ Successfully returned to main app from message compose")
                        }
                    } else {
                        print("✅ Already at main app after message compose")
                    }
                }
            }
        }
    }
}

// MARK: - Mail Compose Delegate
extension SharingManager: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        print("📧 Mail compose finished with result: \(result.rawValue)")
        if let error = error {
            print("❌ Mail compose error: \(error.localizedDescription)")
        }
        
        // Dismiss the mail compose controller
        controller.dismiss(animated: true) {
            // Add a small delay to ensure proper dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    // Make sure we're not stuck in any presentation
                    if rootViewController.presentedViewController != nil {
                        rootViewController.dismiss(animated: true) {
                            print("✅ Successfully returned to main app from mail compose")
                        }
                    } else {
                        print("✅ Already at main app after mail compose")
                    }
                }
            }
        }
    }
}

// MARK: - Sharing Types
enum SharingMethod {
    case icsFile
    case message
    case email
    case link
}

enum SharingError: Error, LocalizedError {
    case messageNotAvailable
    case emailNotAvailable
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .messageNotAvailable:
            return "Messages are not available on this device"
        case .emailNotAvailable:
            return "Email is not configured on this device"
        case .exportFailed:
            return "Failed to export calendar"
        }
    }
}