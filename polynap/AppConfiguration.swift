//
//  Configuration.swift
//  polynap
//
//  Created by Taner Çelik on 11.06.2025.
//


//
//  Configuration.swift
//  polynap
//
//  Created by [Your Name] on [Date].
//

import Foundation

enum AppConfiguration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

// MARK: - API Keys
extension AppConfiguration {
    static var revenueCatAPIKey: String {
        do {
            return try value(for: "RevenueCatAPIKey")
        } catch {
            fatalError("RevenueCat API Key not found in Info.plist. Error: \(error)")
        }
    }
    
    static var superwallAPIKey: String {
        do {
            return try value(for: "SuperwallAPIKey")
        } catch {
            fatalError("Superwall API Key not found in Info.plist. Error: \(error)")
        }
    }
}
