import Foundation

/// A simple in-memory mock of UserDefaults for testing purposes.
class MockUserDefaults: UserDefaults {

    private var storage: [String: Any] = [:]

    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    override func string(forKey defaultName: String) -> String? {
        storage[defaultName] as? String
    }

    override func integer(forKey defaultName: String) -> Int {
        if let number = storage[defaultName] as? NSNumber {
            return number.intValue
        }
        if let intVal = storage[defaultName] as? Int {
            return intVal
        }
        return 0
    }

    override func bool(forKey defaultName: String) -> Bool {
        if let number = storage[defaultName] as? NSNumber {
            return number.boolValue
        }
        if let boolVal = storage[defaultName] as? Bool {
            return boolVal
        }
        return false
    }

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }

    override func removePersistentDomain(forName domainName: String) {
        storage.removeAll()
    }
}