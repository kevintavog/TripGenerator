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
    let images: [ImageInfo]
    let health: [Health]            // Aggregated health stats for the entire trip
    let dailyHealth: [Health]       // health stats for each day, 'date' is set

    public init(_ id: String,
                _ startDate: Date, _ startTimezoneId: String,
                _ endDate: Date, _ endTimezoneId: String,
                _ countries: [TripCountry],
                _ images: [ImageInfo],
                _ health: [Health],
                _ dailyHealth: [Health]) {
        self.id = id
        self.startDate = startDate
        self.startDateTimezoneId = startTimezoneId
        self.endDate = endDate
        self.endDateTimezoneId = endTimezoneId
        self.countries = countries
        self.images = images
        self.health = health
        self.dailyHealth = dailyHealth
    }
}

public class TripDayDetail: Codable {
    let id: String
    let daily: [DayInfo]

    public init(_ id: String, _ daily: [DayInfo]) {
        self.id = id
        self.daily = daily
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

public class TripDailyDetails: Codable {
    let daily: [DayInfo]

    public init(_ daily: [DayInfo]) {
        self.daily = daily
    }

    public func encodeToJson() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

public class DayInfo: Codable {
    let day: String
    let countries: [TripCountry]
    let images: [ImageInfo]         // One image from each day
    let health: [Health]            // Aggregated health stats for the day
    let detailedHealth: [Health]    // Health stats during the day (eg, hourly). 'date' is set

    public init(_ day: String, _ countries: [TripCountry], _ images: [ImageInfo],
                _ health: [Health], _ detailedHealth: [Health]) {
        self.day = day
        self.countries = countries
        self.images = images
        self.health = health
        self.detailedHealth = detailedHealth
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
    var date: Date?
    var steps: Int = 0
    var flights: Int = 0
    var meters: Double = 0

    public init(_ sourceName: String, _ date: Date? = nil) {
        self.sourceName = sourceName
        self.date = date
    }

    public var description: String {
        return "Health for \(sourceName): steps = \(steps), flights = \(flights), distance = \(meters)"
    }
}
