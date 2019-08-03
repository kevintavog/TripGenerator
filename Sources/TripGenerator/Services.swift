import Core

func convertFpDateToDashed(_ fpDate: String) -> String {
    let ymdDate = fpDateFormatter.date(from: fpDate)!
    return ymdDashedDateFormatter.string(from: ymdDate)
}

func getFpTripResults(_ fpClient: HttpCalls, _ first: Int) throws -> FindAPhotoResponse {
    let data = try fpClient.get(
        path: "/api/search?properties=\(tripProperties)&q=\(tripQuery)&first=\(first)&count=100").wait()!
    return try FindAPhotoResponse.fromJson(data: data)
}

func getTimezoneId(_ tlClient: HttpCalls, _ latitude: Double, _ longitude: Double) throws -> String {
    let json = try tlClient.getJson(path: "/api/v1/timezone?lat=\(latitude)&lon=\(longitude)").wait()!
    return json["id"].stringValue
}

func getHealthData(_ hdClient: HttpCalls, _ start: String, _ end: String) throws -> RecordsResponse {
    let data = try hdClient.get(path: "/api/records/\(start)?end=\(end)").wait()!
    return try RecordsResponse.fromJson(data: data)
}
