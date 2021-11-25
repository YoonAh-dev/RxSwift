//
//  ViewController.swift
//  TableView-RxSwift
//
//  Created by SHIN YOON AH on 2021/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ViewController: UIViewController, UITableViewDelegate {
    
    typealias NameSectionModel = SectionModel<String, String>
    typealias NameDataSource = RxTableViewSectionedReloadDataSource<NameSectionModel>

    // MARK: - @IBOutlet
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    let bag = DisposeBag()
    let rows: [String] = ["duna", "huree", "subin", "haley", "nunu", "ez"]
    let ages: [String] = ["25", "24", "22", "26", "25", "23"]
    lazy var rowObservable = Observable.of(rows)
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindTableView()
        datasourceTableView()
    }
    
    // MARK: - Bind
    
    private func bindTableView() {
        /// method 1
        rowObservable
            .bind(to: tableView.rx.items) { (tableView, row, element) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
                cell.textLabel?.text = element
                return cell
            }
            .disposed(by: bag)
        
        /// method 2
        rowObservable
            .bind(to: tableView.rx.items(cellIdentifier: "cell")) { row, element, cell in
                cell.textLabel?.text = element
            }
            .disposed(by: bag)
        
        /// method 3
        rowObservable
            .bind(to: tableView.rx.items(cellIdentifier: "cell")) { [weak self] row, element, cell in
                cell.textLabel?.text = element.description
            }
            .disposed(by: bag)
        
        /// 셀을 선택할 때마다 IndexPath가 가지고 있는 next 이벤트 방출
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: bag)
        
        /// IndexPath가 아니라 실제 모델 데이터를 방출
        tableView.rx.modelSelected(Product.self)
            .subscribe(onNext: {
                print($0.price)
            })
            .disposed(by: bag)
        
        /// Zip메소드를 활용하면 modelSelected, itemSelected를 병합해서 모델 데이터와 인덱스 한꺼번에 방출 가능
        Observable.zip(tableView.rx.modelSelected(Product.self), tableView.rx.itemSelected)
            .bind { [weak self] (product, indexPath) in
                self?.tableView.deselectRow(at: indexPath, animated: true)
                print(product.name)
            }
            .disposed(by: bag)
        
        /// tableview.delegate = self로 delegate를 지정해주면 RxCocoa의 delegate메소드는 더이상 동작하지 않는다.
        /// UITableViewDelegate를 RxCocoa와 같이 사용하고 싶다면 Delegate를 이렇게 지정해줘야 함
        tableView.rx.setDelegate(self)
            .disposed(by: bag)
    }
    
    private func datasourceTableView() {
        let sections = [
            SectionModel<String, String>(model: "first section", items: rows),
            SectionModel<String, String>(model: "second section", items: ages)
        ]
        
        Observable.just(sections)
            .bind(to: tableView.rx.items(dataSource: nameDataSource))
            .disposed(by: bag)
    }
    
    private var nameDataSource: NameDataSource {
        let configureCell: (TableViewSectionedDataSource<NameSectionModel>, UITableView, IndexPath, String) -> UITableViewCell = { (datasource, tableView, indexPath, element) in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
            cell.textLabel?.text = element
            return cell
        }
        
        let datasource = NameDataSource.init(configureCell: configureCell)
        datasource.titleForHeaderInSection = { datasource, index in
            return datasource.sectionModels[index].model
        }
        
        return datasource
    }
    
}

