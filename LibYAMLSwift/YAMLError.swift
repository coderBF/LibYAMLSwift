import Foundation

public struct YAMLError: Error {
    public let problem: String
    public let problemOffset: Int
}
