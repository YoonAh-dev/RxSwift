//
//  APIController.swift
//  Wundercast-Advanced-RxSwift
//
//  Created by SHIN YOON AH on 2021/11/25.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON
import CoreLocation
import MapKit

class APIController {
    
    // MARK: - Shared instance
    
    static var shared = APIController()
    
    // MARK: - Private Properties
    
    private let apiKey = BehaviorSubject(value: "b96003f4589f56458893a32ae638a485")
    private let baseURL = URL(string: "http://api.openweathermap.org/data/2.5")!
    
    // MARK: - Initalizer
    
    init() {
        URLSession.rx.shouldLogRequest = { request in
            return true
        }
    }
    
    // MARK: - API ERROR
    
    enum APIError: Error {
        case cityNotFound
        case serverFailure
        case invalidKey
    }
    
    //MARK: - API Calls
    
    func currentWeather(city: String) -> Observable<Weather> {
        return buildRequest(pathComponent: "weather", params: [("q", city)]).map() { json in
            return Weather(
                cityName: json["name"].string ?? "Unknown",
                temperature: json["main"]["temp"].int ?? -1000,
                humidity: json["main"]["humidity"].int  ?? 0,
                icon: iconNameToChar(icon: json["weather"][0]["icon"].string ?? "e"),
                lat: json["coord"]["lat"].double ?? 0,
                lon: json["coord"]["lon"].double ?? 0
            )
        }
    }
    
    func currentWeather(lat: Double, lon: Double) -> Observable<Weather> {
        return buildRequest(pathComponent: "weather", params: [("lat", "\(lat)"), ("lon", "\(lon)")]).map() { json in
            return Weather(
                cityName: json["name"].string ?? "Unknown",
                temperature: json["main"]["temp"].int ?? -1000,
                humidity: json["main"]["humidity"].int  ?? 0,
                icon: iconNameToChar(icon: json["weather"][0]["icon"].string ?? "e"),
                lat: json["coord"]["lat"].double ?? 0,
                lon: json["coord"]["lon"].double ?? 0
            )
        }
    }
    
    func currentWeatherAround(lat: Double, lon: Double) -> Observable<[Weather]> {
        var weathers = [Observable<Weather>]()
        for i in -1...1 {
            for j in -1...1 {
                weathers.append(currentWeather(lat: lat + Double(i), lon: lon + Double(j)))
            }
        }
        
        return Observable.from(weathers)
            .merge()
            .toArray()
            .asObservable()
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(method: String = "GET",
                              pathComponent: String,
                              params: [(String, String)]) -> Observable<JSON> {
        
        let request: Observable<URLRequest> = Observable.create() { [weak self] observer in
            guard let self = self else { fatalError() }
            let url = self.baseURL.appendingPathComponent(pathComponent)
            let keyQueryItem = URLQueryItem(name: "appid", value: try? self.apiKey.value())
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
            
            observer.onNext(request)
            observer.onCompleted()
            
            return Disposables.create()
        }
        
        let session = URLSession.shared
        
        /// Error의 사용자 화
        return request.flatMap() { request in
            return session.rx.response(request: request).map() { response, data in
                if 200 ..< 300 ~= response.statusCode {
                    return try JSON(data: data)
                } else if response.statusCode == 401 {
                    throw APIError.invalidKey
                } else if 400 ..< 500 ~= response.statusCode {
                    throw APIError.cityNotFound
                } else {
                    throw APIError.serverFailure
                }
            }
        }
    }
    
    // MARK: - Weather
    
    struct Weather {
        let cityName: String
        let temperature: Int
        let humidity: Int
        let icon: String
        let lat: Double
        let lon: Double
        
        static let empty = Weather(
            cityName: "Unknown",
            temperature: -1000,
            humidity: 0,
            icon: iconNameToChar(icon: "e"),
            lat: 0,
            lon: 0
        )
        
        static let dummy = Weather(
          cityName: "RxCity",
          temperature: 20,
          humidity: 90,
          icon: iconNameToChar(icon: "01d"),
          lat: 0,
          lon: 0
        )
        
        var coordinate: CLLocationCoordinate2D {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        func overlay() -> Overlay {
            let coordinates: [CLLocationCoordinate2D] = [
                CLLocationCoordinate2D(latitude: lat - 0.25, longitude: lon - 0.25),
                CLLocationCoordinate2D(latitude: lat + 0.25, longitude: lon + 0.25)
            ]
            let points = coordinates.map { MKMapPoint($0) }
            let rects = points.map { MKMapRect(origin: $0, size: MKMapSize(width: 0, height: 0)) }
            let fittingRect = rects.reduce(MKMapRect.null) { $0.union($1) }
            return Overlay(icon: icon, coordinate: coordinate, boundingMapRect: fittingRect)
        }
        
        public class Overlay: NSObject, MKOverlay {
            var coordinate: CLLocationCoordinate2D
            var boundingMapRect: MKMapRect
            let icon: String
            
            init(icon: String, coordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
              self.coordinate = coordinate
              self.boundingMapRect = boundingMapRect
              self.icon = icon
            }
        }
        
        public class OverlayView: MKOverlayRenderer {
            var overlayIcon: String
            
            init(overlay:MKOverlay, overlayIcon:String) {
                self.overlayIcon = overlayIcon
                super.init(overlay: overlay)
            }
            
            public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
                let imageReference = imageFromText(text: overlayIcon as NSString, font: UIFont(name: "Flaticon", size: 32.0)!).cgImage
                let theMapRect = overlay.boundingMapRect
                let theRect = rect(for: theMapRect)
                
                context.scaleBy(x: 1.0, y: -1.0)
                context.translateBy(x: 0.0, y: -theRect.size.height)
                context.draw(imageReference!, in: theRect)
            }
        }
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

fileprivate func imageFromText(text: NSString, font: UIFont) -> UIImage {
    let size = text.size(withAttributes: [NSAttributedString.Key.font: font])
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    text.draw(at: CGPoint(x: 0, y:0), withAttributes: [NSAttributedString.Key.font: font])
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image ?? UIImage()
}
