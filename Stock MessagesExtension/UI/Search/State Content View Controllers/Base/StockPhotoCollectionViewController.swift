//
//  StockPhotoCollectionViewController.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-21.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

class StockPhotoCollectionViewController: UICollectionViewController {
    static let reuseIdentifier = "Cell", titledHeaderReuseIdentifier = "TitledHeader"
    private let downloader = AttachmentDownloader()
    var numberOfColumns: CGFloat = 0
    
    convenience init() {
        self.init(collectionViewLayout: StockPhotoCollectionViewControllerLayout())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloader.delegate = self
        
        // Collection view appearance and behaviour
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .interactive
        collectionView.alwaysBounceVertical = true

        // Register cell & supplementary view classes
        collectionView!.register(StockPhotoCollectionViewCell.self, forCellWithReuseIdentifier: StockPhotoCollectionViewController.reuseIdentifier)
        collectionView.register(StockPhotoCollectionViewSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StockPhotoCollectionViewController.titledHeaderReuseIdentifier)
        
        determineNumberOfColumns()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
    
    private func determineNumberOfColumns() {
        numberOfColumns = ceil(collectionView.frame.size.width / 150)
    }
    
    var messagesViewController: MessagesViewController {
        return parent as! MessagesViewController
    }
    
    var layout: StockPhotoCollectionViewControllerLayout {
        return collectionView.collectionViewLayout as! StockPhotoCollectionViewControllerLayout
    }
    
    func attach(photo: StockPhoto) {
        downloader.download(photo: photo) { (result) in
            switch result {
            case .success(let attachment):
                self.messagesViewController.activeConversation?.insertAttachment(attachment.fileURL, withAlternateFilename: nil) { (error) in
                    if let error = error { self.showErrorAlert(title: "Couldn't Attach Photo", error: error) }
                    PresentationStyleManager.shared.style = .compact
                    attachment.cleanUp()
                }
            case .failure(let error): self.showErrorAlert(title: "Couldn't Attach Photo", error: error)
            }
        }
    }
    
    // MARK: - Collection view delegate
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? StockPhotoCollectionViewCell else { return }
        cell.isDownloadingFullImage = cell.photo != nil && cell.photo?.fullImageURL == downloader.currentlyDownloadingPhoto?.fullImageURL
    }
}

// MARK: - Collection view layout delegate

extension StockPhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        determineNumberOfColumns()
        
        let usableContainerWidth = collectionView.frame.size.width - (layout.minimumInteritemSpacing * (numberOfColumns - 1)) - layout.sectionInset.horizontal - collectionView.contentInset.horizontal
        let size = usableContainerWidth / numberOfColumns
        
        return CGSize(width: size, height: size)
    }
}

// MARK: - Attachment Downloader Delegate

extension StockPhotoCollectionViewController: AttachmentDownloaderDelegate {
    func currentlyDownloadingPhotoChanged(to photo: StockPhoto?) {
        for cell in collectionView.visibleCells as! [StockPhotoCollectionViewCell] {
            cell.isDownloadingFullImage = cell.photo != nil && cell.photo?.fullImageURL == photo?.fullImageURL
        }
    }
}
