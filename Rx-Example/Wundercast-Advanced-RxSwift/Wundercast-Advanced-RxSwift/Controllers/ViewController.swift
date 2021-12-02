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

typealias Weather = APIController.Weather

var cachedData = [String: Weather]()

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
    @IBOutlet weak var keyButton: UIButton!
    
    var keyTextField: UITextField?
    
    // MARK: - Properties
    
    let bag = DisposeBag()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
        //        bind()
        errorBind()
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
    
    private func errorBind() {
        if RxReachability.shared.startMonitor("apple.com") == false {
            print("Reachability failed!")
        }
        
        keyButton.rx.tap.subscribe(onNext: {
            self.requestKey()
        })
            .disposed(by: bag)
        
        let currentLocation = locationManager.rx.didUpdateLocations
            .map() { locations in
                return locations[0]
            }
            .filter() { location in
                return location.horizontalAccuracy == kCLLocationAccuracyNearestTenMeters
            }
        
        let geoInput = geoLocationButton.rx.tap.asObservable().do(onNext: {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
            
            self.searchCityName.text = "Current Location"
        })
        
        let geoLocation = geoInput.flatMap {
            return currentLocation.take(1)
        }
        
        let geoSearch = geoLocation.flatMap() { location in
            return APIController.shared.currentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                .catchAndReturn(APIController.Weather.empty)
        }
        
        let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").count > 0 }
        
        let maxAttempts = 4
        let retryHandler: (Observable<Error>) -> Observable<Int> = { e in
            return e.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                if attempt >= maxAttempts - 1 {
                    return Observable.error(error)
                } else if let casted = error as? APIController.APIError, casted == .invalidKey {
                    return APIController.shared.apiKey.filter {$0 != ""}.map { _ in return 1 }
                } else if (error as NSError).code == -1009 {
                    return RxReachability.shared.status.filter { $0 == .online }.map { _  in return 1 }
                }
                print("== retrying after \(attempt + 1) seconds ==")
                
                return Observable<Int>.timer(.seconds(attempt + 1), scheduler: MainScheduler.instance).take(1)
            }
        }
        
        let textSearch = searchInput.flatMap { text in
            return APIController.shared.currentWeather(city: text ?? "Error")
                .retry(when: retryHandler)
                .observe(on: MainScheduler.instance).do(onNext: { data in
                    cachedData[text ?? ""] = data
                }, onError: { e in
                    if let e = e as? APIController.APIError {
                        switch e {
                        case .cityNotFound:
                            InfoView.showIn(viewController: self, message: "City Name is invalid")
                        case .serverFailure:
                            InfoView.showIn(viewController: self, message: "Server error")
                        case .invalidKey:
                            InfoView.showIn(viewController: self, message: "Key is invalid")
                        }
                    } else {
                        InfoView.showIn(viewController: self, message: "An error occured")
                    }
                })
                .catch { error in
                    if let text = text, let cachedData = cachedData[text] {
                        return Observable.just(cachedData)
                    } else {
                        return Observable.just(APIController.Weather.empty)
                    }
                }
        }
        
        let search = Observable.from([geoSearch, textSearch])
            .merge()
            .asDriver(onErrorJustReturn: APIController.Weather.empty)
        
        let running = Observable.from([searchInput.map { _ in true },
                                       geoInput.map { _ in true },
                                       search.map { _ in false }.asObservable()])
            .merge()
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        
        search.map { "\($0.temperature)° C" }
        .drive(tempLabel.rx.text)
        .disposed(by:bag)
        
        search.map { $0.icon }
        .drive(iconLabel.rx.text)
        .disposed(by:bag)
        
        search.map { "\($0.humidity)%" }
        .drive(humidityLabel.rx.text)
        .disposed(by:bag)
        
        search.map { $0.cityName }
        .drive(cityNameLabel.rx.text)
        .disposed(by:bag)
        
        running.skip(1).drive(activityIndicator.rx.isAnimating).disposed(by:bag)
        running.drive(tempLabel.rx.isHidden).disposed(by:bag)
        running.drive(iconLabel.rx.isHidden).disposed(by:bag)
        running.drive(humidityLabel.rx.isHidden).disposed(by:bag)
        running.drive(cityNameLabel.rx.isHidden).disposed(by:bag)
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
    
    func requestKey() {
        func configurationTextField(textField: UITextField!) {
            self.keyTextField = textField
        }
        
        let alert = UIAlertController(title: "Api Key",
                                      message: "Add the api key:",
                                      preferredStyle: UIAlertController.Style.alert)
        
        alert.addTextField(configurationHandler: configurationTextField)
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler:{ (UIAlertAction) in
            APIController.shared.apiKey.onNext(self.keyTextField?.text ?? "")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.destructive))
        
        self.present(alert, animated: true)
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
