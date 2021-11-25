//
//  ViewController.swift
//  Wundercast-RxSwift
//
//  Created by SHIN YOON AH on 2021/11/18.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    // MARK: - @IBOutlet
    
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var tempSwitch: UISwitch!
    
    // MARK: - Rx
    
    private let bag = DisposeBag()
    
    // MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fourthExample()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
}

// MARK: - Rx Example
extension ViewController {
    private func firstExample() {
        searchCityName.rx.text
            .filter { ($0 ?? "").count > 0 }
            .flatMapLatest { text in
                return APIController.shared.currentWeather(city: text ?? "Error")
                    .catchAndReturn(APIController.Weather.empty)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { data in
                self.tempLabel.text = "\(data.temperature)° C"
                self.iconLabel.text = data.icon
                self.humidityLabel.text = "\(data.humidity)%"
                self.cityNameLabel.text = data.cityName
            }).disposed(by:bag)
    }
    
    private func secondExample() {
        //      .shareReplay(1)가 있었는데 Error 발생
        
        let search = searchCityName.rx.text
            .filter { ($0 ?? "").count > 0 }
            .flatMapLatest { text in
                return APIController.shared.currentWeather(city: text ?? "Error")
                    .catchAndReturn(APIController.Weather.empty)
            }
            .observe(on: MainScheduler.instance)
        
        search.map { "\($0.temperature)° C" }
        .bind(to: tempLabel.rx.text)
        .disposed(by:bag)
        
        search.map { $0.icon }
        .bind(to: iconLabel.rx.text)
        .disposed(by:bag)
        
        search.map { "\($0.humidity)%" }
        .bind(to: humidityLabel.rx.text)
        .disposed(by:bag)
        
        search.map { $0.cityName }
        .bind(to: cityNameLabel.rx.text)
        .disposed(by:bag)
    }
    
    private func thirdExample() {
        let search = searchCityName.rx.text
            .filter { ($0 ?? "").count > 0 }
            .flatMap { text in
                return APIController.shared.currentWeather(city: text ?? "Error")
                    .catchAndReturn(APIController.Weather.empty)
            }.asDriver(onErrorJustReturn: APIController.Weather.empty)
        
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
    }
    
    private func fourthExample() {
        let textSearch = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
        let temperature = tempSwitch.rx.controlEvent(.valueChanged).asObservable()
        
        let search = Observable.from([textSearch, temperature])
            .merge()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").count > 0 }
            .flatMap { text in
                return APIController.shared.currentWeather(city: text ?? "Error")
                    .catchAndReturn(APIController.Weather.empty)
            }.asDriver(onErrorJustReturn: APIController.Weather.empty)
        
        search.map { w in
            if self.tempSwitch.isOn {
                return "\(Int(Double(w.temperature) * 1.8 + 32))° F"
            }
            return "\(w.temperature)° C"
        }
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
    }
}
