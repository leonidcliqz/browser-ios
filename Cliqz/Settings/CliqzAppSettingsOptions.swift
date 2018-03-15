//
//  CliqzAppSettingsOptions.swift
//  Client
//
//  Created by Mahmoud Adam on 3/13/18.
//  Copyright © 2018 Cliqz. All rights reserved.
//

import Foundation

// MARK:- cliqz settings
class HumanWebSetting: CliqzOnOffSetting {
    
    override func getTitle() -> String {
        return NSLocalizedString("Human Web", tableName: "Cliqz", comment: "[Settings] Human Web")
    }
    
    override func isOn() -> Bool {
        return SettingsPrefs.shared.getHumanWebPref()
    }
    
    override func getSubSettingViewController() -> SubSettingsTableViewController {
        return HumanWebSettingsTableViewController()
    }
}


class AutoForgetTabSetting: CliqzOnOffSetting {
    
    override func getTitle() -> String {
        return NSLocalizedString("Automatic Forget Tab", tableName: "Cliqz", comment: " [Settings] Automatic Forget Tab")
    }
    
    override func isOn() -> Bool {
        return SettingsPrefs.shared.getAutoForgetTabPref()
    }
    
    override func getSubSettingViewController() -> SubSettingsTableViewController {
        return AutoForgetTabTableViewController()
    }
    
}


class LimitMobileDataUsageSetting: CliqzOnOffSetting {
    override func getTitle() -> String {
        return NSLocalizedString("Limit Mobile Data Usage", tableName: "Cliqz", comment: "[Settings] Limit Mobile Data Usage")
    }
    
    override func isOn() -> Bool {
        return SettingsPrefs.shared.getLimitMobileDataUsagePref()
    }
    
    override func getSubSettingViewController() -> SubSettingsTableViewController {
        return LimitMobileDataUsageTableViewController()
    }
    
}

class AdBlockerSetting: CliqzOnOffSetting {
    override func getTitle() -> String {
        return NSLocalizedString("Block Ads", tableName: "Cliqz", comment: "[Settings] Block Ads")
    }
    
    override func isOn() -> Bool {
        return SettingsPrefs.shared.getAdBlockerPref()
    }
    
    override func getSubSettingViewController() -> SubSettingsTableViewController {
        return AdBlockerSettingsTableViewController()
    }
}


class SupportSetting: Setting {
    
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("FAQ & Support", tableName: "Cliqz", comment: "[Settings] FAQ & Support"),attributes: [NSForegroundColorAttributeName: UIConstants.HighlightBlue])
    }
    
    override var url: URL? {
        return URL(string: "https://cliqz.com/support")
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true, completion: {})
        self.delegate?.settingsOpenURLInNewTab(self.url!)
        
        // TODO: Telemetry
        /*
        // Cliqz: log telemetry signal
        let contactSignal = TelemetryLogEventType.Settings("main", "click", "contact", nil, nil)
        TelemetryLogger.sharedInstance.logEvent(contactSignal)
        */
    }
    
}

class CliqzTipsAndTricksSetting: ShowCliqzPageSetting {
    
    override func getTitle() -> String {
        return NSLocalizedString("Get the best out of CLIQZ", tableName: "Cliqz", comment: "[Settings] Get the best out of CLIQZ")
    }
    
    override func getPageName() -> String {
        return "tips-ios"
    }
}

class ReportWebsiteSetting: ShowCliqzPageSetting {
    
    override func getTitle() -> String {
        return NSLocalizedString("Report Website", tableName: "Cliqz", comment: "[Settings] Report Website")
    }
    
    override func getPageName() -> String {
        return "report-url"
    }
}

class MyOffrzSetting: ShowCliqzPageSetting {
    
    override func getTitle() -> String {
        return NSLocalizedString("About MyOffrz", tableName: "Cliqz", comment: "[Settings] About MyOffrz")
    }
    
    override func getPageName() -> String {
        return "myoffrz"
    }
}

