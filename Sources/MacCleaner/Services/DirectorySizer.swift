import Foundation

protocol DirectorySizing: Sendable {
    func sizeOfItem(at url: URL) throws -> Int64
}

struct DirectorySizer: DirectorySizing {
    func sizeOfItem(at url: URL) throws -> Int64 {
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey]
        let values = try url.resourceValues(forKeys: resourceKeys)
        if values.isDirectory == true {
            var total: Int64 = 0
            let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )

            while let nextURL = enumerator?.nextObject() as? URL {
                let nextValues = try nextURL.resourceValues(forKeys: resourceKeys)
                if nextValues.isDirectory == true {
                    continue
                }

                total += Int64(nextValues.fileSize ?? 0)
            }

            return total
        }

        return Int64(values.fileSize ?? 0)
    }
}
