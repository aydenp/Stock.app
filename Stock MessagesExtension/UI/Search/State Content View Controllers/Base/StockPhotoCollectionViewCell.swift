//
//  StockPhotoCollectionViewCell.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit
import StockKit

class StockPhotoCollectionViewCell: UICollectionViewCell {
    private var imageView = UIImageView()
    private var downloadIndicatorView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor(named: "imagePlaceholder")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.pinToSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photo = nil
    }
    
    var photo: StockPhoto? {
        didSet {
            accessibilityLabel = photo?.alternativeText
            photoURL = photo?.thumbnailURL ?? photo?.fullImageURL
        }
    }

    var isDownloadingFullImage = false {
        didSet {
            guard oldValue != isDownloadingFullImage else { return }
            DispatchQueue.main.async {
                if self.isDownloadingFullImage {
                    let downloadIndicatorView = UIView()
                    downloadIndicatorView.backgroundColor = UIColor(named: "downloadIndicatorOverlay")
                    downloadIndicatorView.translatesAutoresizingMaskIntoConstraints = false
                    self.contentView.addSubview(downloadIndicatorView)
                    downloadIndicatorView.pinToSuperview()
                    
                    let activityIndicator = UIActivityIndicatorView(style: .white)
                    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                    activityIndicator.hidesWhenStopped = false
                    activityIndicator.startAnimating()
                    downloadIndicatorView.addSubview(activityIndicator)
                    activityIndicator.centerXAnchor.constraint(equalTo: downloadIndicatorView.centerXAnchor).isActive = true
                    activityIndicator.centerYAnchor.constraint(equalTo: downloadIndicatorView.centerYAnchor).isActive = true
                    
                    self.downloadIndicatorView = downloadIndicatorView
                    
                } else {
                    self.downloadIndicatorView?.removeFromSuperview()
                    self.downloadIndicatorView = nil
                }
            }
        }
    }
    
    private var photoURL: URL? {
        didSet {
            guard oldValue != photoURL else { return }
            imageView.image = nil
            if let oldValue = oldValue { ThumbnailManager.shared.stopReceivingThumbnail(at: oldValue, for: self) }
            
            guard let url = photoURL else { return }
            ThumbnailManager.shared.getThumbnail(at: url, for: self)
        }
    }
    
    private func set(image: UIImage?) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { self.set(image: image) }
            return
        }
        UIView.animate(withDuration: image != nil ? 0.25 : 0) {
            self.imageView.image = image
        }
    }
    
    private var currentDataTask: URLSessionDataTask? {
        didSet {
            oldValue?.cancel()
            currentDataTask?.resume()
        }
    }
}

extension StockPhotoCollectionViewCell: ThumbnailReceiving {
    func received(thumbnail: UIImage, from url: URL) {
        guard photoURL == url else { return }
        set(image: thumbnail)
    }
}
