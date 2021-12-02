//
//  RxReachability.swift
//  Wundercast-Advanced-RxSwift
//
//  Created by SHIN YOON AH on 2021/12/02.
//

import SystemConfiguration
import Foundation
import RxSwift
import RxRelay

enum Reachability {
    case offline
    case online
    case unknown
    
    init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
        let connectionRequired = flags.contains(.connectionRequired)
        let isReachable = flags.contains(.reachable)
        
        self = (!connectionRequired && isReachable) ? .online : .offline
    }
}

class RxReachability {
    static let shared = RxReachability()
    
    fileprivate init() { }
    
    private static var _status = BehaviorRelay<Reachability>(value: .unknown)
    private var reachability: SCNetworkReachability?
    
    var status: Observable<Reachability> {
        get {
            return RxReachability._status.asObservable().distinctUntilChanged()
        }
    }
    
    class func reachabilityStatus() -> Reachability {
        return RxReachability._status.value
    }
    
    func isOnline() -> Bool {
        switch RxReachability._status.value {
        case .online:
            return true
        case .offline, .unknown:
            return false
        }
    }
    
    func startMonitor(_ host: String) -> Bool {
        if let _ = reachability {
            return true
        }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        
        if let reachability = SCNetworkReachabilityCreateWithName(nil, host) {
            
            SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
                let status = Reachability(reachabilityFlags: flags)
                RxReachability._status.accept(status)
            }, &context)
            
            SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
            self.reachability = reachability
            
            return true
        }
        
        return true
    }
    
    func stopMonitor() {
        if let _reachability = reachability {
            SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
            reachability = nil
        }
    }
}
