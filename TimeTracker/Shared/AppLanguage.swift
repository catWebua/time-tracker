import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case ukrainian = "uk"
    case english = "en"

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .ukrainian:
            return "Українська"
        case .english:
            return "English"
        }
    }

    static var current: AppLanguage {
        UserDefaults.standard.string(forKey: storageKey)
            .flatMap(AppLanguage.init(rawValue:))
            ?? .ukrainian
    }
}

enum AppLocalization {
    static func string(_ resource: LocalizedStringResource) -> String {
        var resource = resource
        resource.locale = AppLanguage.current.locale
        return String(localized: resource)
    }

    static func string(forKey key: String) -> String {
        switch AppLanguage.current {
        case .ukrainian:
            return key
        case .english:
            guard
                let path = Bundle.main.path(forResource: AppLanguage.english.rawValue, ofType: "lproj"),
                let bundle = Bundle(path: path)
            else {
                return key
            }

            return bundle.localizedString(forKey: key, value: key, table: "Localizable")
        }
    }
}
