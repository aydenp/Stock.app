//
//  PresentationStyleManager.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-19.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation
import Messages

class PresentationStyleManager {
    static let willChangeNotification = Notification.Name(rawValue: "PresentationStyleManager.willChangeNotification.name"), didChangeNotification = Notification.Name(rawValue: "PresentationStyleManager.didChangeNotification.name")
    static let shared = PresentationStyleManager()
    private var appController: MSMessagesAppViewController!
    typealias UpdateBlock = () -> Void
    
    private init() {}
    
    var style: MSMessagesAppPresentationStyle {
        get { return appController.presentationStyle }
        set { appController.requestPresentationStyle(newValue) }
    }
    
    // MARK: - Observers
    
    private var styleWillChangeObservers = [MSMessagesAppPresentationStyle: Set<UUID>](), styleDidChangeObservers = [MSMessagesAppPresentationStyle: Set<UUID>]()
    private var observers = [UUID: UpdateBlock]()
    
    func onWillChange(to style: MSMessagesAppPresentationStyle,  _ block: @escaping UpdateBlock) -> UUID {
        let token = _registerObserver(block)
        if !styleWillChangeObservers.keys.contains(style) { styleWillChangeObservers[style] = Set<UUID>() }
        styleWillChangeObservers[style]!.insert(token)
        return token
    }
    
    func onDidChange(to style: MSMessagesAppPresentationStyle,  _ block: @escaping UpdateBlock) -> UUID {
        let token = _registerObserver(block)
        if !styleDidChangeObservers.keys.contains(style) { styleDidChangeObservers[style] = Set<UUID>() }
        styleDidChangeObservers[style]!.insert(token)
        return token
    }
    
    func deregisterChangeNotifications(token: UUID) {
        observers.removeValue(forKey: token)
    }
    
    private func _registerObserver(_ block: @escaping UpdateBlock) -> UUID {
        let token = UUID()
        observers[token] = block
        return token
    }
    
    // MARK: - Internal (called from app controller)
    
    fileprivate func _setup(with appController: MSMessagesAppViewController) {
        self.appController = appController
    }
    
    fileprivate func _willTransition(to style: MSMessagesAppPresentationStyle) {
        NotificationCenter.default.post(name: PresentationStyleManager.willChangeNotification, object: self, userInfo: ["style": style])
        guard let observerTokens = styleWillChangeObservers[style] else { return }
        observerTokens.forEach { observers[$0]?() }
    }
    
    fileprivate func _didTransition(to style: MSMessagesAppPresentationStyle) {
        NotificationCenter.default.post(name: PresentationStyleManager.didChangeNotification, object: self, userInfo: ["style": style])
        guard let observerTokens = styleDidChangeObservers[style] else { return }
        observerTokens.forEach { observers[$0]?() }
    }
}

extension MessagesViewController {
    func setupPresentationStyleManager() {
        PresentationStyleManager.shared._setup(with: self)
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
        PresentationStyleManager.shared._willTransition(to: presentationStyle)
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        PresentationStyleManager.shared._didTransition(to: presentationStyle)
    }
}
