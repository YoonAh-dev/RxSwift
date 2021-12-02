//
//  InfoView.swift
//  Wundercast-Advanced-RxSwift
//
//  Created by SHIN YOON AH on 2021/12/02.
//

import UIKit

class InfoView: UIView {

    @IBOutlet var textLabel: UILabel!
    @IBOutlet var closeButton: UIButton!
    
    private static var sharedView: InfoView!
    
    static func loadFromNib() -> InfoView {
        let nibName = "\(self)".split { $0 == "." }.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as! InfoView
    }
    
    static func showIn(viewController: UIViewController, message: String) {
        
        var displayVC = viewController
        
        if let tabController = viewController as? UITabBarController {
            displayVC = tabController.selectedViewController ?? viewController
        }
        
        if sharedView == nil {
            sharedView = loadFromNib()
            
            sharedView.layer.masksToBounds = false
            sharedView.layer.shadowColor = UIColor.darkGray.cgColor
            sharedView.layer.shadowOpacity = 1
            sharedView.layer.shadowOffset = CGSize(width: 0, height: 3)
        }
        
        sharedView.textLabel.text = message
        
        if sharedView.superview == nil {
            let y = displayVC.view.frame.height - sharedView.frame.size.height - 12
            sharedView.frame = CGRect(x: 12, y: y, width: displayVC.view.frame.size.width - 24, height: sharedView.frame.size.height)
            sharedView.alpha = 0.0
            
            displayVC.view.addSubview(sharedView)
            sharedView.fadeIn()
            
            sharedView.perform(#selector(fadeOut), with: nil, afterDelay: 3.0)
        }
    }
    
    @IBAction func closePressed(_ sender: Any) {
        fadeOut()
    }
    
    // MARK: Animations
    func fadeIn() {
        UIView.animate(withDuration: 0.33, animations: {
            self.alpha = 1.0
        })
    }
    
    @objc func fadeOut() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        UIView.animate(withDuration: 0.33, animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}
