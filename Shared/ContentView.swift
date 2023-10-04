//
//  ContentView.swift
//  Shared
//
//  Created by Graham Pennington on 8/17/22.
//

import SwiftUI
import MapKit

struct ContentView: View {
   
    let rangeSelection = [0.1, 0.01, 0.001, 0.0001]
    
    @StateObject var vmObserved: CityDataViewModel = CityDataViewModel()
    @ObservedObject var localSearchVM: LocalSearchViewModel = LocalSearchViewModel()
    @State private var searchRange: Double = 0.1
    @State private var mapCoordRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900,
                                       longitude: -122.009_020),
        latitudinalMeters: 7500, longitudinalMeters: 7500)
    @State private var currentSearchLatitude: CLLocationDegrees = 0.0
    
    var annotations: [CoordinateData] {
        if vmObserved.filteredCities.isEmpty {
            return []
        } else if vmObserved.filteredCities.count < 10 {
            return vmObserved.filteredCities.map { cityData in
                CoordinateData(city: cityData.city,
                               coordinate: CLLocationCoordinate2D(
                                latitude: cityData.lat,
                                longitude: cityData.lng),
                               iso2: cityData.iso2)
            }
        } else {
            return vmObserved.filteredCities[0...10].map { cityData in
                CoordinateData(city: cityData.city,
                               coordinate: CLLocationCoordinate2D(
                                latitude: cityData.lat,
                                longitude: cityData.lng),
                               iso2: cityData.iso2)
            }
        }
    }
    
    var body: some View {
            VStack {
                Map(coordinateRegion: $mapCoordRegion, annotationItems: annotations) {
                    MapMarker(coordinate: $0.coordinate)
                }
                Picker("Range", selection: $searchRange) {
                    ForEach(rangeSelection, id:\.self) { range in
                        Text(String(range))
                    }
                }
                .padding()
                List {
                    if vmObserved.filteredCities.count == 0 {
                        Text("No cities found within range")
                    } else {
                        ForEach(vmObserved.filteredCities, id:\.self) { cityData in
                            HStack {
                                Text(cityData.city)
                                Spacer()
                                VStack {
                                    Text(cityData.country)
                                    Text("\(cityData.lat)")
                                }
                            }
                            .padding()
                        }
                    }
                }
            }.searchable(text: $localSearchVM.searchText, prompt: Text("Dallas")) {
                ForEach(localSearchVM.completions, id: \.self) { completion in
                    Text(completion.title).searchCompletion(completion.title)
                }
            }
            .onChange(of: searchRange, perform: { newValue in
                if currentSearchLatitude != 0.0 {
                    vmObserved.filterDataByLatitude(cityLatitude: currentSearchLatitude, range: newValue)
                }
            })
            .onSubmit(of: .search) {
                Task {
                    print("Fetching data...")
                    do {
                        if !localSearchVM.searchText.isEmpty {
                            var localSearchRequest: MKLocalSearch.Request
                            if (!localSearchVM.completions.isEmpty) {
                                localSearchRequest = MKLocalSearch.Request(completion: localSearchVM.completions[0])
                            } else {
                                print("oh boy, it's empty")
                                localSearchRequest = MKLocalSearch.Request()
                                localSearchRequest.naturalLanguageQuery = localSearchVM.searchText
                                localSearchRequest.region = MKCoordinateRegion(.world)
                                localSearchRequest.resultTypes = .address
                            }
                            
                            let search = MKLocalSearch(request: localSearchRequest)
                            let response = try await search.start()
                            if (response.mapItems.count != 0) {
                                if let coordinate = response.mapItems.first?.placemark.coordinate {
                                    currentSearchLatitude = coordinate.latitude
                                    withAnimation {
                                        mapCoordRegion.center = coordinate
                                    }
                                    vmObserved.filterDataByLatitude(cityLatitude: coordinate.latitude, range: searchRange)
//                                    try await vmObserved.getCitiesData(cityLatitude: coordinate.latitude, range: searchRange)
                                }
                            }
                        } else {
                            vmObserved.filteredCities = []
                        }
                    } catch let error as ViewModelError {
                        print(error)
                    }
                    
                }
            }
    }
}
