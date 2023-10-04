//
//  LocalSearchViewModel.swift
//  LatitudeSimilarity
//
//  Created by Graham Pennington on 9/5/22.
//

import Foundation
import MapKit
import Combine

class LocalSearchViewModel: NSObject, ObservableObject {
    
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var searchText: String = ""
    
    private let searchCompleter: MKLocalSearchCompleter
    private var queryCancellable: AnyCancellable?
    
    override init() {
        self.searchCompleter = MKLocalSearchCompleter()
        super.init()
        self.searchCompleter.delegate = self
        self.searchCompleter.resultTypes = .address
        
        queryCancellable = $searchText
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .sink(receiveValue: { fragment in
                if !fragment.isEmpty {
                    self.searchCompleter.queryFragment = fragment
                } else {
                    self.completions = []
                }
            })
    }
}

extension LocalSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
        print("done")
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Completer failed")
        print(error)
    }
}
