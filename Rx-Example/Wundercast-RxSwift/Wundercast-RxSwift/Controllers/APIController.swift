//
//  APIController.swift
//  Wundercast-RxSwift
//
//  Created by SHIN YOON AH on 2021/11/18.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON

class APIController {
    
    // MARK: - Weather
    
    struct Weather {
        let cityName: String
        let temperature: Int
        let humidity: Int
        let icon: String
        
        static let empty = Weather(
            cityName: "Unknown",
            temperature: -1000,
            humidity: 0,
            icon: iconNameToChar(icon: "e")
        )
    }
    
    // MARK: - Shared instance
    
    static var shared = APIController()
    
    // MARK: - Private Properties
    
    private let apiKey = "b96003f4589f56458893a32ae638a485"
    private let baseURL = URL(string: "http://api.openweathermap.org/data/2.5")!
    
    // MARK: - Initalizer
    
    init() {
        URLSession.rx.shouldLogRequest = { request in
            return true
        }
    }
    
    //MARK: - API Calls
    
    func currentWeather(city: String) -> Observable<Weather> {
        return buildRequest(pathComponent: "weather", params: [("q", city)]).map() { json in
            return Weather(
                cityName: json["name"].string ?? "Unknown",
                temperature: json["main"]["temp"].int ?? -1000,
                humidity: json["main"]["humidity"].int  ?? 0,
                icon: iconNameToChar(icon: json["weather"][0]["icon"].string ?? "e"))
        }
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(method: String = "GET",
                              pathComponent: String,
                              params: [(String, String)]) -> Observable<JSON> {
        let url = baseURL.appendingPathComponent(pathComponent)
        let keyQueryItem = URLQueryItem(name: "appid", value: apiKey)
        let unitsQueryItem = URLQueryItem(name: "units", value: "metric")
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        var request = URLRequest(url: url)
        
        switch method {
        case "GET":
            var queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
            queryItems.append(keyQueryItem)
            queryItems.append(unitsQueryItem)
            urlComponents.queryItems = queryItems
        default:
            urlComponents.queryItems = [keyQueryItem, unitsQueryItem]
            
            let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request.httpBody = jsonData
        }
        
        request.url = urlComponents.url!
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        
        return session.rx.data(request: request)
                         .compactMap { try? JSON(data: $0) }
    }
}

public func iconNameToChar(icon: String) -> String {
    switch icon {
    case "01d":
        return "\u{f11b}"
    case "01n":
        return "\u{f110}"
    case "02d":
        return "\u{f112}"
    case "02n":
        return "\u{f104}"
    case "03d", "03n":
        return "\u{f111}"
    case "04d", "04n":
        return "\u{f111}"
    case "09d", "09n":
        return "\u{f116}"
    case "10d", "10n":
        return "\u{f113}"
    case "11d", "11n":
        return "\u{f10d}"
    case "13d", "13n":
        return "\u{f119}"
    case "50d", "50n":
        return "\u{f10e}"
    default:
        return "E"
    }
}
