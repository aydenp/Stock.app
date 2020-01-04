//
//  SettingsViewController.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-21.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit
import StockKit

private let reuseIdentifier = "Cell", buttonReuseIdentifier = "ButtonCell"

class SettingsViewController: UITableViewController {
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: buttonReuseIdentifier)
    }
    
    @objc func dismissModal() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return StockPhotoSearchManager.shared.allServices.count
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Providers"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return "Stock retrieves photos from a variety of stock photo providers. You can toggle which providers are used when searching.\n\nStock is not endorsed by or affiliated with these services in any way."
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: buttonReuseIdentifier, for: indexPath) as! ButtonTableViewCell
            cell.title = "Clear Recent Items"
            cell.selectionStyle = .default
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
            let service = type(of: StockPhotoSearchManager.shared.allServices[indexPath.item])
            
            cell.textLabel!.text = service.name
            cell.accessoryType = StockPhotoSearchManager.shared.blacklistedServiceIdentifiers.contains(service.identifier) ? .none : .checkmark
            
            return cell
        default: fatalError("I don't know about this section!")
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            let alert = UIAlertController.createAlert(title: "Clear Recent Items?", message: "This cannot be undone.", preferredStyle: .actionSheet, actions: [
                .destructive("Clear Recents") { _ in
                    PersistentStockPhotoStore.recents.clear()
            }, .cancel])
            
            let cell = tableView.cellForRow(at: indexPath)
            alert.popoverPresentationController?.sourceView = cell
            alert.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
            
            present(alert, animated: true, completion: nil)
        case 1:
            let service = type(of: StockPhotoSearchManager.shared.allServices[indexPath.item])
            if StockPhotoSearchManager.shared.blacklistedServiceIdentifiers.contains(service.identifier) {
                StockPhotoSearchManager.shared.blacklistedServiceIdentifiers.remove(service.identifier)
            } else {
                if StockPhotoSearchManager.shared.allServices.count >  StockPhotoSearchManager.shared.blacklistedServiceIdentifiers.count + 1 {
                    StockPhotoSearchManager.shared.blacklistedServiceIdentifiers.insert(service.identifier)
                }
            }
            tableView.reloadRows(at: [indexPath], with: .fade)
        default: break
        }
    }

}
