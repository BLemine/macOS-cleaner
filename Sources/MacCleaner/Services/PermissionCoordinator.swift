import Foundation

enum ReadAccessValidation: Equatable {
    case allowed
    case denied(String)
}

protocol PermissionCoordinating: Sendable {
    func validateReadAccess(to url: URL) -> ReadAccessValidation
}

struct PermissionCoordinator: PermissionCoordinating {
    func validateReadAccess(to url: URL) -> ReadAccessValidation {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .denied("Path does not exist.")
        }

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return .denied("Permission denied. Root access was not granted.")
        }

        return .allowed
    }
}
