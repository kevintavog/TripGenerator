import Foundation

public enum TGError: Error {
    case httpError(status: UInt, message: String)
}
