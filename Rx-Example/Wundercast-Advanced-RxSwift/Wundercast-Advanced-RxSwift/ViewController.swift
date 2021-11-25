//
//  ViewController.swift
//  Wundercast-Advanced-RxSwift
//
//  Created by SHIN YOON AH on 2021/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    // MARK: - @IBOutlet
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    
    // MARK: - Properties
    
    let bag = DisposeBag()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
    
    private func bind() {
        let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").count > 0 }
        
        let textSearch = searchInput.flatMap { text in
            return APIController.shared.currentWeather(city: text ?? "Error")
                .catchAndReturn(APIController.Weather.dummy)
        }
        
        let mapInput = mapView.rx.regionDidChangeAnimated
            .skip(1)
            .map { _ in self.mapView.centerCoordinate }
        
        let mapSearch = mapInput.flatMap { coordinate in
            return APIController.shared.currentWeather(lat: coordinate.latitude, lon: coordinate.longitude)
                .catchAndReturn(APIController.Weather.dummy)
        }
        
        let currentLocation = locationManager.rx.didUpdateLocations
            .map { location in
                return location[0]
            }
            .filter { location in
                return location.horizontalAccuracy < kCLLocationAccuracyHundredMeters
            }
        
        let geoInput = geoLocationButton.rx.tap.asObservable()
            .do(onNext: {
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            })
                
        let geoLocation = geoInput.flatMap {
            return currentLocation.take(1)
        }
                
        let geoSearch = geoLocation.flatMap { location in
            return APIController.shared.currentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                .catchAndReturn(APIController.Weather.dummy)
        }
                
        let search = Observable.from([geoSearch, textSearch, mapSearch])
                .merge()
                .asDriver(onErrorJustReturn: APIController.Weather.dummy)
                
        let running = Observable.from([searchInput.map { _ in true },
                                       geoInput.map { _  in true },
                                       mapInput.map { _ in true },
                                       search.map { _ in false }.asObservable()])
                .merge()
                .startWith(true)
                .asDriver(onErrorJustReturn: false)
                
        running
            .skip(1)
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: bag)
                
        running
                .drive(tempLabel.rx.isHidden)
                .disposed(by: bag)
                
        running
                .drive(iconLabel.rx.isHidden)
                .disposed(by: bag)
                
        running
                .drive(humidityLabel.rx.isHidden)
                .disposed(by: bag)

        running
                .drive(cityNameLabel.rx.isHidden)
                .disposed(by: bag)
                
        search.map { "\($0.temperature)° C" }
                .drive(tempLabel.rx.text)
                .disposed(by: bag)

        search.map { $0.icon }
                .drive(iconLabel.rx.text)
                .disposed(by: bag)

        search.map { "\($0.humidity)%" }
                .drive(humidityLabel.rx.text)
                .disposed(by: bag)

        search.map { $0.cityName }
                .drive(cityNameLabel.rx.text)
                .disposed(by: bag)
        
        locationManager.rx.didUpdateLocations
          .subscribe(onNext: { locations in
            print(locations)
          })
          .disposed(by: bag)

        mapButton.rx.tap
          .subscribe(onNext: {
            self.mapView.isHidden = !self.mapView.isHidden
          })
          .disposed(by: bag)

        mapView.rx.setDelegate(self)
          .disposed(by: bag)

        search.map { [$0.overlay()] }
          .drive(mapView.rx.overlays)
          .disposed(by: bag)

        textSearch.asDriver(onErrorJustReturn: APIController.Weather.dummy)
          .map { $0.coordinate }
          .drive(mapView.rx.location)
          .disposed(by: bag)

        mapInput.flatMap { coordinate in
          return APIController.shared.currentWeatherAround(lat: coordinate.latitude, lon: coordinate.longitude)
                .catchAndReturn([])
          }
          .asDriver(onErrorJustReturn:[])
          .map { $0.map { $0.overlay() } }
          .drive(mapView.rx.overlays)
          .disposed(by: bag)
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? APIController.Weather.Overlay {
            let overlayView = APIController.Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
            return overlayView
        }
        return MKOverlayRenderer()
    }
}
