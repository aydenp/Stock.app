//
//  SearchStateController.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import UIKit

enum SearchState: Equatable {
    /// The user has not inputted anything.
    case noQuery
    /// The user has inputted a query, but to avoid extraneous network requests and ensure the user has finished typing, the bar is currently intentionally waiting before providing the input.
    case inputTimeout
    /// The user has inputted a query, which is now provided.
    case queryEntered(String)
    
    /// The query, if available in this state.
    var query: String? {
        switch self {
        case .queryEntered(let query): return query
        default: return nil
        }
    }
}

class SearchStateController {
    weak var delegate: SearchStateControllerDelegate?
    
    func searchBarTextDidChange(_ searchBar: UISearchBar) {
        computeState(for: searchBar.text)
    }
    
    func searchBarDidEndEditing(_ searchBar: UISearchBar) {
        computeState(for: searchBar.text, editingEnded: true)
    }
    
    var state: SearchState {
        return _state
    }
    
    private var _state = SearchState.noQuery {
        didSet {
            guard _state != oldValue else { return }
            delegate?.searchStateChanged(to: _state)
        }
    }
    
    private func computeState(for input: String?, editingEnded: Bool = false) {
        let query = input?.trimmingCharacters(in: .whitespacesAndNewlines)
        timeoutTimer?.invalidate()
        
        // If we have no query, set state and return
        if query?.isEmpty ?? true {
            _state = .noQuery
            return
        }
        
        // Check if we have to wait for a timer
        if inputTimeoutDuration > 0 && !editingEnded {
            startTimeout(with: query!)
            return
        }
        
        // We can provide it immediately!
        _state = .queryEntered(query!)
    }
    
    private var timeoutTimer: Timer?
    private func startTimeout(with query: String) {
        _state = .inputTimeout
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: inputTimeoutDuration, repeats: false) { _ in
            self._state = .queryEntered(query)
        }
    }
    
    // MARK: - Properties
    
    /**
    The duration to wait before providing input after a query has been entered to ensure the user has stopped typing. Specify zero to disable the timeout period and immediately provide queries.
     
    **Default:** 0.5 (seconds)
         */
    var inputTimeoutDuration: TimeInterval = 0.5
}

protocol SearchStateControllerDelegate: class {
    func searchStateChanged(to state: SearchState)
}
