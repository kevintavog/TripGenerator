import Foundation

public struct RecordsResponse: Codable {
    public let records: [DayRecord]

    static public func fromJson(data: Data) throws -> RecordsResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(RecordsResponse.self, from: data)
    }
}

public struct DayRecord: Codable {
    public let dayDateUTC: Date    // Date only, time is not part of this
    public let steps: [StepRecord]
    public let devices: [DeviceRecord]
    public let distances: [DistanceRecord]
    public let flights: [FlightsRecord]
}

public struct StepRecord: Codable {
    public let sourceName: String
    public let records: [CountRecord]
}

public struct FlightsRecord: Codable {
    public let sourceName: String
    public let records: [CountRecord]
}

public struct DistanceRecord: Codable {
    public let sourceName: String
    public let records: [MeterRecord]
}

public struct DeviceRecord: Codable {
    public let deviceName: String
    public let name: String
    public let hardware: String
    public let manufacturer: String
    public let model: String
}

public struct CountRecord: Codable {
    public let count: Int
    public let startUTC: Date
    public let endUTC: Date
    public let sourceName: String
}

public struct MeterRecord: Codable {
    public let meters: Double
    public let sourceName: String
    public let startUTC: Date
    public let endUTC: Date
}
