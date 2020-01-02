//
//  MessagesViewController.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-19.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit
import Messages

@objc(MessagesViewController)
class MessagesViewController: MSMessagesAppViewController {
    private var headerView: HeaderView!
    private var noQueryViewController: NoQueryViewController!, searchViewController: SearchCollectionViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPresentationStyleManager()
        view.backgroundColor = UIColor(named: "background")
        
        // Keyboard avoidance
        updateSafeAreaKeyboardInset()
        NotificationCenter.default.addObserver(self, selector: #selector(updateSafeAreaKeyboardInset), name: PresentationStyleManager.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameWillChange(with:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        // Setup header
        headerView = HeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        headerView.pinToSuperview(edges: [.top, .left, .right])
        headerView.inputBar.settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        
        // Setup search controller delegate
        headerView.inputBar.searchStateController.delegate = self
        
        // Setup content view controllers
        noQueryViewController = NoQueryViewController()
        searchViewController = SearchCollectionViewController()
        
        // Set active content view controller
        currentContentViewController = contentViewController(for: headerView.inputBar.searchStateController.state)
    }
    
    @objc func settingsTapped() {
        let viewController = ExpansionEnforcingNavigationController(rootViewController: SettingsViewController())
        // On iOS 13 phones, form sheet looks weird (a sheet nested inside... another sheet), so use full screen instead
        viewController.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .phone ? .fullScreen : .formSheet
        if #available(iOS 13.0, *) {
            viewController.isModalInPresentation = true
        }
        
        present(viewController, animated: true, completion: nil)
    }
    
    // MARK: - Content View Controller Setup
    
    private var currentContentViewController: UIViewController? {
        didSet {
            // Remove previous view controller
            if let oldValue = oldValue {
                oldValue.willMove(toParent: nil)
                oldValue.view.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.beginFromCurrentState], animations: {
                    self.applyAnimationProperties(to: oldValue.view, isIn: false)
                }) { _ in
                    guard oldValue != self.currentContentViewController else { return }
                    oldValue.removeFromParent()
                    oldValue.view.removeFromSuperview()
                }
            }
            
            guard let viewController = currentContentViewController else { return }
            // Add new view controller!
            addChild(viewController)
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            self.applyAnimationProperties(to: viewController.view, isIn: false)
            view.addSubview(viewController.view)
            viewController.view.pinToSuperview(edges: [.left, .bottom, .right])
            viewController.view.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.beginFromCurrentState], animations: {
                self.applyAnimationProperties(to: viewController.view, isIn: true)
            }) { _ in
                guard viewController == self.currentContentViewController else { return }
                viewController.didMove(toParent: self)
            }
        }
    }
    
    private func applyAnimationProperties(to view: UIView, isIn: Bool) {
        view.transform = isIn ? .identity : CGAffineTransform.identity.scaledBy(x: 0.9, y: 0.9)
        view.alpha = isIn ? 1 : 0
    }
    
    private func contentViewController(for state: SearchState) -> UIViewController? {
        searchViewController.query = state.query
        switch state {
        case .noQuery: return noQueryViewController
        case .queryEntered(_): return searchViewController
        default: return nil
        }
    }
    
    // MARK: - Keyboard Safe Area Avoidance
    
    @objc private func keyboardFrameWillChange(with notification: Notification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let localKeyboardFrame = view.convert(keyboardFrame, from: view.window)
        let keyboardInsetFromBottom = (view.window?.screen.bounds ?? view.bounds).height - localKeyboardFrame.minY
        
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber).map { UIView.AnimationOptions(rawValue: $0.uintValue) } ?? .curveEaseInOut
        
        safeAreaKeyboardInset = PresentationStyleManager.shared.style == .expanded ? keyboardInsetFromBottom - (view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom) : 0
        UIView.animate(withDuration: duration, delay: 0, options: curve, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private var safeAreaKeyboardInset: CGFloat = 0 {
        didSet { updateSafeAreaKeyboardInset() }
    }
    
    @objc func updateSafeAreaKeyboardInset() {
        self.additionalSafeAreaInsets.bottom = PresentationStyleManager.shared.style == .expanded ? safeAreaKeyboardInset : 0
    }
}

extension MessagesViewController: SearchStateControllerDelegate {
    func searchStateChanged(to state: SearchState) {
        currentContentViewController = contentViewController(for: state)
        
        // Hide settings if query is entered
        switch state {
        case .noQuery: headerView.inputBar.settingsButton.isHidden = false
        default: headerView.inputBar.settingsButton.isHidden = true
        }
    }
}
