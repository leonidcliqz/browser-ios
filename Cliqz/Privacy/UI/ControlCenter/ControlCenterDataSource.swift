//
//  ControlCenterDataSource.swift
//  Client
//
//  Created by Tim Palade on 4/23/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import UIKit
import Storage

enum TableType {
    case page
    case global
}

enum ActionType: Int {
    case trust
    case untrust
    case block
    case unblock
    case restrict
    case unrestrict
    
    static func positives() -> [ActionType] {
        return [.block, .restrict, .trust]
    }
    
    static func negatives() -> [ActionType] {
        return [.unblock, .unrestrict, .untrust]
    }
    
    static func complement(_ action: ActionType) -> ActionType {
        switch action {
        case .trust:
            return .untrust
        case .untrust:
            return .trust
        case .block:
            return .unblock
        case .unblock:
            return .block
        case .restrict:
            return .unrestrict
        case .unrestrict:
            return .restrict
        }
    }
    
    static func action(state: TrackerUIState) -> ActionType? {
        switch state {
        case .empty:
            return nil
        case .trusted:
            return .trust
        case .restricted:
            return .restrict
        case .blocked:
            return .block
        }
    }
}

enum CategoryState {
    case blocked
    case restricted
    case trusted
    case empty
    case other
    
    static func from(trackerState: TrackerUIState) -> CategoryState {
        switch trackerState {
        case .blocked:
            return .blocked
        case .restricted:
            return .restricted
        case .trusted:
            return .trusted
        case .empty:
            return .empty
        }
    }
}

protocol ControlCenterDelegateProtocol: class {
    func pauseGhostery(paused: Bool, time: Date)
    func turnGlobalAdblocking(on: Bool)
    func turnDomainAdblocking(on: Bool?, completion: @escaping () -> Void)
    func changeState(category: String, state: TrackerUIState, tableType: TableType, completion: @escaping () -> Void)
    func changeState(appId: Int, state: TrackerUIState, tableType: TableType, section: Int, emptyState: EmptyState, completion: @escaping () -> Void)
    func undoState(appIds: [Int], tableType: TableType, completion: @escaping () -> Void)
    func undoAll(tableType: TableType, completion: @escaping () -> Void)
    func blockAll(tableType: TableType, completion: @escaping () -> Void)
    func unblockAll(tableType: TableType, completion: @escaping () -> Void)
    func changeAll(state: TrackerUIState, tableType: TableType, completion: @escaping () -> Void)
    func restoreDefaultSettings(tableType: TableType, completion: @escaping () -> Void)
}

enum LastAction: Int {
    case block
    case unblock
    case undo
}

protocol ControlCenterDSProtocol: class {
    
    func domainString() -> String?
    func domainState() -> DomainState?
	// TODO: Temporary workaround to fix a bug in trust/restrict actions. Undo logic should be changed soon
	func domainPrevState() -> DomainState?
    func countAndColorByCategory(tableType: TableType) -> Dictionary<String, (Int, UIColor)>
    func detectedTrackerCount() -> Int
    func blockedTrackerCount() -> Int
    func isGhosteryPaused() -> Bool
    func isGlobalAntitrackingOn() -> Bool
    func isAdblockerOn() -> Bool
    func antitrackingCount() -> Int
    
    //SECTIONS
    func numberOfSections(tableType: TableType) -> Int
    func numberOfRows(tableType: TableType, section: Int) -> Int
    func title(tableType: TableType, section: Int) -> String
    func image(tableType: TableType, section: Int) -> UIImage?
    func category(_ tableType: TableType, _ section: Int) -> String
    func categoryState(_ tableType: TableType, _ section: Int) -> CategoryState
    func trackerCount(tableType: TableType, section: Int) -> Int
    func blockedTrackerCount(tableType: TableType, section: Int) -> Int
    func stateIcon(tableType: TableType, section: Int) -> UIImage?
    
    //INDIVIDUAL TRACKERS
    func title(tableType: TableType, indexPath: IndexPath) -> (String?, NSMutableAttributedString?)
    func stateIcon(tableType: TableType, indexPath: IndexPath) -> UIImage?
    func appId(tableType: TableType, indexPath: IndexPath) -> Int
    func actions(tableType: TableType, indexPath: IndexPath) -> [ActionType]
    
    //OTHER
    func shouldShowBlockAll(tableType: TableType) -> Bool
    func shouldShowUnblockAll(tableType: TableType) -> Bool
    func shouldShowUndo(tableType: TableType) -> Bool
}

final class CategoriesHelper {
    static let categories = Set(arrayLiteral: "advertising", "audio_video_player", "comments", "customer_interaction", "essential", "pornvertising", "site_analytics", "social_media", "uncategorized")
    static let categoriesBlockedByDefault = Set(arrayLiteral: "pornvertising", "site_analytics", "advertising")
    static let category2NameAndColor = ["advertising": (NSLocalizedString("Advertising", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "CB55CD")),
                                 "audio_video_player": (NSLocalizedString("Audio/Video Player", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "EF671E")),
                                 "comments": (NSLocalizedString("Comments", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "43B7C5")),
                                 "customer_interaction": (NSLocalizedString("Customer Interaction", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "FDC257")),
                                 "essential": (NSLocalizedString("Essential", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "FC9734")),
                                 "pornvertising": (NSLocalizedString("Adult Advertising", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "ECAFC2")),
                                 "site_analytics": (NSLocalizedString("Site Analytics", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "87D7EF")),
                                 "social_media": (NSLocalizedString("Social Media", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "388EE8")),
                                 "uncategorized": (NSLocalizedString("Uncategorized", tableName: "Cliqz", comment: "Tracker category in control center"), UIColor(colorString: "8459A5"))]
}

class ControlCenterModel: ControlCenterDSProtocol {
    
    var domainStr: String? {
        didSet {
            //refresh?
        }
    }
    
    var url: URL? {
        didSet {
            domainStr = url?.normalizedHost
        }
    }
    
    
    //Make sure to invalidate these on updates
    var blockedTrackerCountCache: [TableType: [Int: Int]] = [.page: [:], .global: [:]] // section is the key
    var stateImageCache: [TableType: [Int: UIImage]] = [.page: [:], .global: [:]] //section is the key
    
    func domainString() -> String? {
        return self.domainStr
    }

    func countAndColorByCategory(tableType: TableType) -> Dictionary<String, (Int, UIColor)> {
        
        var countDict: [String: Int] = [:]
        if let domain = self.domainStr, tableType == .page {
            countDict = TrackerList.instance.countByCategory(domain: domain)
        }
        else if tableType == .global {
            countDict = TrackerList.instance.countByCategory
        }
        
        var dict: Dictionary<String, (Int, UIColor)> = [:]
        for (index, key) in countDict.keys.enumerated() {
			if let count = countDict[key], let color = getColor((index, key)) {
                dict[key] = (count, color)
            }
        }
        return dict
    }

    func detectedTrackerCount() -> Int {
        return TrackerList.instance.detectedTrackerCountForPage(self.domainStr)
    }
    
    func domainState() -> DomainState? {
        guard let domain = self.domainStr else { return nil }
        
        let trackers = TrackerList.instance.detectedTrackersForPage(domain)
        var set: Set<TrackerUIState> = Set()
        for tracker in trackers {
            set.insert(tracker.state(domain: domain))
        }
        
        if set.count == 1 {
            if set.first == .trusted {
                return .trusted
            }
            else if set.first == .restricted {
                return .restricted
            }
        }
        
        return .empty
    }

	func domainPrevState() -> DomainState? {
		guard let domain = self.domainStr else { return nil }
		
		let trackers = TrackerList.instance.detectedTrackersForPage(domain)
		var set: Set<TrackerUIState> = Set()
		for tracker in trackers {
			set.insert(tracker.prevState(domain: domain))
		}
		
		if set.count == 1 {
			if set.first == .trusted {
				return .trusted
			}
			else if set.first == .restricted {
				return .restricted
			}
		}
		
		return .empty
	}

    func blockedTrackerCount() -> Int {
        guard let domain = self.domainStr else { return 0 }
        
        let domainS = domainState()
        
        if domainS == .trusted || UserPreferences.instance.pauseGhosteryMode == .paused {
            return 0
        } else if domainS == .restricted {
            return detectedTrackerCount()
        }
        else {
            return TrackerList.instance.detectedTrackersForPage(domain).filter { (app) -> Bool in
                let appState = app.state(domain: self.domainStr)
                return appState == .blocked || appState == .restricted
            }.count
        }
    }
    
    func isGhosteryPaused() -> Bool {
        return UserPreferences.instance.pauseGhosteryMode == .paused
    }
    
    func isGlobalAntitrackingOn() -> Bool {
        return UserPreferences.instance.antitrackingMode == .blockAll
    }
    
    func isAdblockerOn() -> Bool {
        if let domainString = self.domainStr {
            //PROBLEM: this takes too long 
            if let domain = DomainStore.get(domain: domainString) {
                if domain.translatedAdblockerState() == .on {
                    return true
                }
                else if domain.translatedAdblockerState() == .off {
                    return false
                }
            }
            else {
                print("DOMAIN not found")
            }
        }
        
        return UserPreferences.instance.adblockingMode == .blockAll
    }
    
    func antitrackingCount() -> Int {
        return self.blockedTrackerCount()
    }
    
    //SECTIONS
    func numberOfSections(tableType: TableType) -> Int {
        return source(tableType).keys.count
    }
    
    func numberOfRows(tableType: TableType, section: Int) -> Int {
        return trackers(tableType: tableType, category: category(tableType, section)).count
    }
    
    func title(tableType: TableType, section: Int) -> String {
        if let touple = CategoriesHelper.category2NameAndColor[category(tableType, section)] {
            return touple.0
        }
        return ""
    }
    
    func image(tableType: TableType, section: Int) -> UIImage? {
        return UIImage(named: category(tableType, section))
    }
    
    func category(_ tableType: TableType, _ section: Int) -> String {
        var categories: [String] = []
        if let domain = self.domainStr, tableType == .page {
            categories.append(contentsOf: TrackerList.instance.categories(domain: domain))
        }
        else if tableType == .global {
            categories.append(contentsOf: TrackerList.instance.categories)
        }
        
        guard categories.isIndexValid(index: section) else { return "" }
        return categories[section]
    }
    
    func categoryState(_ tableType: TableType, _ section: Int) -> CategoryState {
        
        let t = trackers(tableType: tableType, category: category(tableType, section))
        
        func trackerStates() -> Set<TrackerUIState> {
            
            var set: Set<TrackerUIState> = Set()
            
            let domain: String? = tableType == .page ? self.domainStr : nil
            
            for tracker in t {
                set.insert(tracker.state(domain: domain))
            }
            
            return set
        }
        
        let set = trackerStates()
        
        let state: CategoryState
        
        if set.count == 1 {
            state = CategoryState.from(trackerState: set.first!)
        }
        else if set.count > 0{
            state = .other
        }
        else {
            state = .empty
        }
        
        return state
    }
 
    func trackerCount(tableType: TableType, section: Int) -> Int {
        return self.numberOfRows(tableType: tableType, section: section)
    }
    
    func blockedTrackerCount(tableType: TableType, section: Int) -> Int {
        
        if let count = blockedTrackerCountCache[tableType]?[section] {
            return count
        }
        
        let count = trackers(tableType: tableType, category: category(tableType, section)).filter({ (app) -> Bool in
            let appState = tableType == .page ? app.state(domain: self.domainStr) : app.state(domain: nil)
            return appState == .blocked || appState == .restricted
        }).count
        
        blockedTrackerCountCache[tableType]?[section] = count
        
        return count
    }
    
    func stateIcon(tableType: TableType, section: Int) -> UIImage? {
        
        if let image = stateImageCache[tableType]?[section] {
            return image
        }
        
        let state = categoryState(tableType, section)

        let image = iconForCategoryState(state: state)
        
        stateImageCache[tableType]?[section] = image
        
        return image
    }
    
    //INDIVIDUAL TRACKERS
    func title(tableType: TableType, indexPath: IndexPath) -> (String?, NSMutableAttributedString?) {
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return (nil, nil) }
        let state: TrackerUIState = tableType == .page ? t.state(domain: self.domainStr) : t.state(domain: nil)
        
        if state == .blocked || (tableType == .page && state == .restricted) {
            let str = NSMutableAttributedString(string: t.name)
            str.addAttributes([NSAttributedStringKey.strikethroughStyle: 1], range: NSMakeRange(0, t.name.count))
            return (nil, str)
        }
        
        return (t.name, nil)
    }
    
    func stateIcon(tableType: TableType, indexPath: IndexPath) -> UIImage? {
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return nil }
        return tableType == .page ? iconForTrackerState(state: t.state(domain: self.domainStr)) : iconForTrackerState(state: t.state(domain: nil))
    }
    
    func appId(tableType: TableType, indexPath: IndexPath) -> Int {
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return -1 }
        return t.appId
    }
    
    func actions(tableType: TableType, indexPath: IndexPath) -> [ActionType] {
        
        guard let t = tracker(tableType: tableType, indexPath: indexPath) else { return [] }
        
        let state = tableType == .page ? t.state(domain: self.domainStr) : t.state(domain: nil)
        
        if tableType == .page {
            
            if isGhosteryPaused() == true {
                return []
            }
            
            var returnList: [ActionType] = []
            for action in ActionType.positives() {
                if action == ActionType.action(state: state) {
                    returnList.append(ActionType.complement(action))
                }
                else {
                    returnList.append(action)
                }
            }
            return returnList
        }
        
        if state == .blocked {
            return [.unblock]
        }
        
        return [.block]
    }
    
    func shouldShowBlockAll(tableType: TableType) -> Bool {
        
        if areAllTrackersInState(.blocked, tableType: tableType) {
            return false
        }
        
        return true
    }
    
    func shouldShowUnblockAll(tableType: TableType) -> Bool {
        
        if areAllTrackersInState(.empty, tableType: tableType) {
            return false
        }
        
        return true
    }
    
    func shouldShowUndo(tableType: TableType) -> Bool {
        if areAllTrackersInState(.empty, tableType: tableType) {
            return true
        }
        
        if areAllTrackersInState(.blocked, tableType: tableType) {
            return true
        }
        
        return false
    }
    
    func invalidateStateImageCache(tableType: TableType? = nil, section: Int? = nil) {
        if let t = tableType {
            if let s = section {
                stateImageCache[t]?.removeValue(forKey: s)
            }
            else {
                stateImageCache[t]? = [:]
            }
        }
        else {
            if let s = section {
                stateImageCache[.global]?.removeValue(forKey: s)
                stateImageCache[.page]?.removeValue(forKey: s)
            }
            else {
                stateImageCache = [.page: [:], .global: [:]]
            }
        }
    }
    
    func invalidateBlockedCountCache(tableType: TableType? = nil, section: Int? = nil) {
        if let t = tableType {
            if let s = section {
                blockedTrackerCountCache[t]?.removeValue(forKey: s)
            }
            else {
                blockedTrackerCountCache[t]? = [:]
            }
        }
        else {
            if let s = section {
                blockedTrackerCountCache[.global]?.removeValue(forKey: s)
                blockedTrackerCountCache[.page]?.removeValue(forKey: s)
            }
            else {
                blockedTrackerCountCache = [.page: [:], .global: [:]]
            }
        }
    }
}

// MARK: - Helpers
extension ControlCenterModel {
    
    fileprivate func source(_ tableType: TableType) -> Dictionary<String, [TrackerListApp]> {
        if tableType == .page {
            return TrackerList.instance.trackersByCategory(domain: self.domainStr!)
        }
        
        return TrackerList.instance.appsByCategory
    }
    
    fileprivate func trackers(tableType: TableType, category: String) -> [TrackerListApp] {
        return source(tableType)[category] ?? []
    }
    
    fileprivate func tracker(tableType: TableType, indexPath: IndexPath) -> TrackerListApp? {
        let (section, row) = sectionAndRow(indexPath: indexPath)
        let t = trackers(tableType: tableType, category: category(tableType, section))
        guard t.isIndexValid(index: row) else { return nil }
        return t[row]
    }
    
    fileprivate func sectionAndRow(indexPath: IndexPath) -> (Int, Int) {
        return (indexPath.section, indexPath.row)
    }
    
    fileprivate func iconForTrackerState(state: TrackerUIState?) -> UIImage? {
        if let state = state {
            switch state {
            case .empty:
                return UIImage(named: "empty")
            case .blocked:
                return UIImage(named: "blockTracker")
            case .restricted:
                return UIImage(named: "restrictTracker")
            case .trusted:
                return UIImage(named: "trustTracker")
            }
        }
        return nil
    }
    
    fileprivate func iconForCategoryState(state: CategoryState?) -> UIImage? {
        if let state = state {
            switch state {
            case .empty:
                return UIImage(named: "empty")
            case .blocked:
                return UIImage(named: "blockTracker")
            case .restricted:
                return UIImage(named: "restrictTracker")
            case .trusted:
                return UIImage(named: "trustTracker")
            case .other:
				return UIImage(named: "minus")

            }
        }
        return nil
    }
    
    fileprivate func areAllTrackersInState(_ state: TrackerUIState, tableType: TableType) -> Bool {
        
        let trackers = source(tableType)
        let domain =  tableType == .page ? self.domainStr : nil
        
        var returnValue = true
        
        for key in trackers.keys {
            for app in trackers[key]! {
                if app.state(domain: domain) != state {
                    returnValue = false
                    break
                }
            }
        }
        
        return returnValue
    }

	fileprivate func getColor(_ pair: (index: Int, key: String)) -> UIColor? {
		if UserPreferences.instance.pauseGhosteryMode == .paused {
			return UIColor.ControlCenter.pausedColorSet[pair.index]
		} else if self.domainState() == .restricted {
			return UIColor.ControlCenter.restrictedColorSet[pair.index]
		}
		return CategoriesHelper.category2NameAndColor[pair.key]?.1
	}

}
