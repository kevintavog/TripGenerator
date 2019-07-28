import Foundation

public class FindAPhotoResponse: Codable {
    let groups: [FPGroupResponse]
    let resultCount: Int
    let totalMatches: Int

    static public func fromJson(data: Data) throws -> FindAPhotoResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FindAPhotoResponse.self, from: data)
    }
}

public class FPGroupResponse: Codable {
    let name: String
    let items: [FPGroupItemResponse]
    let locations: [FPGroupLocationResponse]
}

public class FPGroupItemResponse: Codable {
    let city: String
    let country: String
    let createdDate: Date
    let date: String
    let latitude: Double?
    let longitude: Double?
    let mediaURL: String
    let sitename: String        // NOTE: Comma separated
    let thumbURL: String
}

public class FPGroupLocationResponse: Codable {
    let country: String
    let states: [FPGroupLocationStateResponse]
}

public class FPGroupLocationStateResponse: Codable {
    let state: String
    let cities: [FPGroupLocationCityResponse]
}

public class FPGroupLocationCityResponse: Codable {
    let city: String
    let sites: [FPGroupLocationSiteResponse]
}

public class FPGroupLocationSiteResponse: Codable {
    let site: String
}
