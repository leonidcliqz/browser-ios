//
//  DomainStore.swift
//  Client
//
//  Created by Tim Palade on 4/23/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import Foundation
import RealmSwift

public class Domain: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var adblockerState: Int = 0 // 0 none, 1 on, 2 off
    //assumption: appIds are unique in these lists. Make sure your code enforces this.
    public var trustedTrackers = List<Int>()
    public var restrictedTrackers = List<Int>()
    public var previouslyTrustedTrackers = List<Int>()
    public var previouslyRestrictedTrackers = List<Int>()
    
    override static public func primaryKey() -> String? {
        return "name"
    }
    
    public func translatedAdblockerState() -> AdblockerDomainState {
        if adblockerState == 1 {
            return .on
        }
        else if adblockerState == 2 {
            return .off
        }
        
        return .none
    }
    
    public class func intForState(_ state: AdblockerDomainState) -> Int {
        
        if state == .on {
            return 1
        }
        else if state == .off {
            return 2
        }
        
        return 0
    }
}

public enum AdblockerDomainState {
    case none
    case on
    case off
}

public enum DomainState {
    case empty
    case trusted
    case restricted
}

public enum ListType {
    case trustedList
    case restrictedList
    case prevTrustedList
    case prevRestrictedList
}

public class DomainStore: NSObject {
    
    public class func get(domain: String) -> Domain? {
        if let realm = try? Realm() {
            if let domain = realm.object(ofType: Domain.self, forPrimaryKey: domain) {
                return domain
            }
        }
        return nil
    }
    
    public class func changeAdblockerState(toState: AdblockerDomainState, domain: String) {
        autoreleasepool {
            if let realm = try? Realm() {
                
                guard realm.isInWriteTransaction == false else { return } //avoid exceptions
                realm.beginWrite()
                
                if let domainObj = realm.object(ofType: Domain.self, forPrimaryKey: domain) {
                    domainObj.adblockerState = Domain.intForState(toState)
                    realm.add(domainObj, update: true)
                }
                else {
                    let domainObj = Domain()
                    domainObj.name = domain
                    domainObj.adblockerState = Domain.intForState(toState)
                    realm.add(domainObj)
                }
                
                do {
                    try realm.commitWrite()
                }
                catch {
                    debugPrint("could not change state of trackerState")
                    //do I need to cancel the write?
                }
            }
        }
    }
}
