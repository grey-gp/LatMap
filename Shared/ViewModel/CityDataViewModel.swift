//
//  CityDataViewModel.swift
//  LatitudeSimilarity
//
//  Created by Graham Pennington on 9/1/22.
//

import Foundation
import CoreLocation

enum ViewModelError: Error {
       case URLError
       case DataError
}
    
@MainActor
class CityDataViewModel: ObservableObject {
    
    @Published var citiesData: [CityData] = []
    @Published var filteredCities: [CityData] = []
    
    private var jsonFileData: [CityData] = []
    
    init() {
        try? loadJSONData()
    }
    
    func loadJSONData() throws {
        do {
            if let bundlePath = Bundle.main.path(forResource: "cleaned_city_data", ofType: "json"),
               let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8){
                jsonFileData = try JSONDecoder().decode([CityData].self, from: jsonData)
            }
        } catch let error as ViewModelError {
            print(error)
        }
        print("Finished loading json data")
    }
    
    func filterDataByLatitude(cityLatitude: CLLocationDegrees, range: Double) {
        filteredCities = []
        filteredCities = jsonFileData.filter { abs(cityLatitude - $0.lat) <= range }
    }
    
    func getCitiesData(cityLatitude: CLLocationDegrees, range: Double) async throws {
        citiesData = []
        guard let url = URL(string: "http://localhost:3000/cities?latitude=\(cityLatitude)&range=\(range)") else { throw ViewModelError.URLError }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let newData = try? JSONDecoder().decode([CityData].self, from: data) else { throw ViewModelError.DataError }
        citiesData.append(contentsOf: newData)
    }
}
