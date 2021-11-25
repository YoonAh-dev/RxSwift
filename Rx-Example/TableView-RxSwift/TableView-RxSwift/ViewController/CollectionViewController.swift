//
//  CollectionViewController.swift
//  TableView-RxSwift
//
//  Created by SHIN YOON AH on 2021/11/25.
//

import UIKit
import RxSwift
import RxCocoa

class CollectionViewController: UIViewController, UICollectionViewDelegate {

    // MARK: - @IBOutlet
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    
    let bag = DisposeBag()
    let colors: [UIColor] = [.blue, .red, .orange, .purple, .white, .black, .green, .systemPink]
    lazy var colorObservable = Observable.of(colors)
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    // MARK: - Bind
    
    private func bindCollectionView() {
        colorObservable
            .bind(to: collectionView.rx.items(cellIdentifier: "collectionCell", cellType: UICollectionViewCell.self)) { index, color, cell in
                cell.backgroundColor = color
            }
            .disposed(by: bag)
        
        /// item 선택
        collectionView.rx.itemSelected
            .subscribe(onNext: { index in
                print("\(index.section) \(index.row)")
            })
            .disposed(by: bag)
        
        /// model 데이터 방출
        collectionView.rx.modelSelected(UIColor.self)
            .subscribe(onNext: { color in
                print(color.description)
            })
            .disposed(by: bag)
        
        /// UICollectionViewDelegate 사용
        collectionView.rx.setDelegate(self)
            .disposed(by: bag)
    }
    
}
