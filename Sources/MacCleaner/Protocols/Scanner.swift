import Foundation

protocol Scanner<Item>: Sendable {
    associatedtype Item: Sendable
    func scan() -> AsyncStream<ScanEvent<Item>>
}
