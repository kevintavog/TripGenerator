import Foundation

public class GeneratedTrips: Codable {
    let trips: [TripInfo]

    public init(_ trips: [TripInfo]) {
        self.trips = trips
    }

    public func encodeToJson() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

public class TripInfo: Codable {
    let id: String
    let startDate: Date
    let startDateTimezoneId: String
    let endDate: Date
    let endDateTimezoneId: String
    let countries: [TripCountry]
    let health: [Health]
    let daily: [DayInfo]

    public init(_ id: String,
                _ startDate: Date, _ startTimezoneId: String,
                _ endDate: Date, _ endTimezoneId: String,
                _ countries: [TripCountry], _ daily: [DayInfo],
                _ health: [Health]) {
        self.id = id
        self.startDate = startDate
        self.startDateTimezoneId = startTimezoneId
        self.endDate = endDate
        self.endDateTimezoneId = endTimezoneId
        self.countries = countries
        self.daily = daily
        self.health = health
    }
}

public class TripCountry: Codable, CustomStringConvertible {
    let name: String
    let cities: [TripCity]

    public init(_ name: String, _ cities: [TripCity]) {
        self.name = name
        self.cities = cities
    }

    public var description: String {
        return "Country: \(name), \(cities)"
    }
}

public class DayInfo: Codable {
    let day: String
    let countries: [TripCountry]
    let health: [Health]
    let images: [ImageInfo]

    public init(_ day: String, _ countries: [TripCountry], _ health: [Health], _ images: [ImageInfo]) {
        self.day = day
        self.countries = countries
        self.health = health
        self.images = images
    }
}

public class ImageInfo: Codable {
    let thumbURL: String
    let city: String
    let country: String
    let createdDate: Date
    let sitename: String        // NOTE: Comma separated

    public init(_ thumbURL: String, _ createdDate: Date, _ city: String, _ country: String, _ sitename: String) {
        self.thumbURL = thumbURL
        self.createdDate = createdDate
        self.city = city
        self.country = country
        self.sitename = sitename
    }
}

public class TripCity: Codable, CustomStringConvertible {
    let name: String
    let sites: [String]

    public init(_ name: String, _ sites: [String]) {
        self.name = name
        self.sites = sites
    }

    public var description: String {
        return "City: \(name), \(sites.count) sites"
    }
}

public class Health: Codable, CustomStringConvertible {
    let sourceName: String
    var steps: Int = 0
    var flights: Int = 0
    var meters: Double = 0

    public init(_ sourceName: String) {
        self.sourceName = sourceName
    }

    public var description: String {
        return "Health for \(sourceName): steps = \(steps), flights = \(flights), distance = \(meters)"
    }
}
