import Core
import Guaka
import SwiftyJSON

let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let ymdDashedDateFormatter = DateFormatter()
ymdDashedDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
ymdDashedDateFormatter.dateFormat = "yyyy-MM-dd"

let hourDateFormatter = DateFormatter()
hourDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
hourDateFormatter.dateFormat = "yyyy-MM-dd-hh"

// FindAPhoto returns a 'date' string field in yyyyMMdd format and it needs to be converted to date instance
let fpDateFormatter = DateFormatter()
fpDateFormatter.dateFormat = "yyyyMMdd"


let tripProperties = "city,createdDate,country,date,id,latitude,longitude,mediaType,mediaURL,sitename,thumbURL"
let tripQuery = "keywords:trip AND date:>20141101".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!

let findAPhotoUrlFlag = Flag(shortName: "f", longName: "findAPhotoUrl", type: String.self, description: "The URL for the FindAPhoto service", required: true)
let healthDataUrlFlag = Flag(shortName: "d", longName: "healthDataUrl", type: String.self, description: "The URL for the HealthData service", required: true)
let outputFolderFlag = Flag(shortName: "o", longName: "outputFolder", type: String.self, description: "The folder to write the output file.", required: true)
let timezoneLookupUrlFlag = Flag(shortName: "t", longName: "timezoneLookupUrl", type: String.self, description: "The URL for the TimezoneLookup service", required: true)


let flags = [findAPhotoUrlFlag, healthDataUrlFlag, outputFolderFlag, timezoneLookupUrlFlag]

var trips = [TripInfo]()


func getHour(_ date: Date) -> String {
    return hourDateFormatter.string(from: date)
}

//-------------------------------------------------------------------------------------------------
func aggregateHealth(_ raw: RecordsResponse) -> ([Health], [String:[Health]], [String:[Health]]) {
    if raw.records.count < 0 {
        return ([Health](), [String:[Health]](), [String:[Health]]())
    }

    // A map of device/source name -> Health (aggregate for the trip)
    var devAggregateMap = [String:Health]()
    for dev in raw.records.first!.devices {
        devAggregateMap[dev.deviceName] = Health(dev.deviceName)
    }

    //  A map of map of day -> [Health] (an instance per device/source name)
    var dailyHealthMap = [String:[Health]]()
    var hourlyHealthMap = [String: [Health]]()

    // Aggregate each device over each day, for all data types
    for day in raw.records {
        let ymdDate = ymdDashedDateFormatter.string(from: day.dayDateUTC)
        for step in day.steps {
            let tripHealth = devAggregateMap[step.sourceName]!
            let daily = step.records.reduce(0) { $0 + $1.count }
            findDayHealth(&dailyHealthMap, ymdDate, step.sourceName).steps = daily
            tripHealth.steps += daily

            for sr in step.records {
                findHourHealth(&hourlyHealthMap, getHour(sr.startUTC), step.sourceName).steps += sr.count
            }
        }
        for flight in day.flights {
            let tripHealth = devAggregateMap[flight.sourceName]!
            let daily = flight.records.reduce(0) { $0 + $1.count }
            findDayHealth(&dailyHealthMap, ymdDate, flight.sourceName).flights = daily
            tripHealth.flights += daily

            for sr in flight.records {
                findHourHealth(&hourlyHealthMap, getHour(sr.startUTC), flight.sourceName).flights += sr.count
            }
        }
        for distance in day.distances {
            let tripHealth = devAggregateMap[distance.sourceName]!
            let daily = distance.records.reduce(0.0) { $0 + $1.meters }
            findDayHealth(&dailyHealthMap, ymdDate, distance.sourceName).meters += daily
            tripHealth.meters += daily

            for sr in distance.records {
                findHourHealth(&hourlyHealthMap, getHour(sr.startUTC), distance.sourceName).meters += sr.meters
            }
        }
    }

    let tripHealthList = devAggregateMap.values.filter { $0.steps > 0 || $0.flights > 0 || $0.meters > 0}
    return (tripHealthList, dailyHealthMap, hourlyHealthMap)
}

func findDayHealth(_ dayHealthMap: inout [String:[Health]], _ ymdDate: String, _ sourceName: String) -> Health {
    var dayList = dayHealthMap[ymdDate, default: [Health]()]
    dayHealthMap[ymdDate] = dayList
    for d in dayList {
        if d.sourceName == sourceName {
            return d
        }
    }
    let health = Health(sourceName)
    dayList.append(health)
    dayHealthMap[ymdDate] = dayList
    return health
}

func findHourHealth(_ hourHealthMap: inout [String:[Health]], _ hour: String, _ sourceName: String) -> Health {
    var hourList = hourHealthMap[hour, default: [Health]()]
    hourHealthMap[hour] = hourList
    for h in hourList {
        if h.sourceName == sourceName {
            return h
        }
    }
    let health = Health(sourceName)
    health.date = hourDateFormatter.date(from: hour)
    hourList.append(health)
    hourHealthMap[hour] = hourList
    return health
}

func aggregatePhotos(_ collection: [FPGroupResponse], _ findAPhotoUrl: String) -> 
        ([TripCountry], [String:[TripCountry]], [String:[ImageInfo]], FPGroupItemResponse, FPGroupItemResponse) {
    // Aggregates for the entire trip
    var countryCityMap = [String:Set<String>]()
    var citySiteMap = [String:Set<String>]()

    for group in collection {
        for loc in group.locations {
            var cityNames = countryCityMap[loc.country, default: Set<String>()]
            for state in loc.states {
                for city in state.cities {
                    cityNames.insert(city.city)
                    var siteNames = citySiteMap[city.city, default: Set<String>()]
                    for site in city.sites {
                        siteNames.insert(site.site)
                    }
                    citySiteMap[city.city] = siteNames
                }
            }
            countryCityMap[loc.country] = cityNames
        }
    }

    let tripCountry = countryCityMap.map { (country: String, citySet: Set<String>) -> TripCountry in
        let tripCityList = citySet.map { (cityName) in
            TripCity(cityName, Array(citySiteMap[cityName]!).sorted())
        }
        return TripCountry(country, tripCityList.sorted { $0.name < $1.name })
    }

    // Day: Country
    var dayCountryMap = [String:Set<String>]()
    // Day: [ Country: Cities<> ]
    var dayCountryCitiesMap = [String:[String:Set<String>]]()
    // Day: [ City: Sites<> ]
    var dayCitySiteMap = [String:[String:Set<String>]]()

    var dayImagesMap = [String:[ImageInfo]]()

    var earliest = collection.first!.items.first!
    var latest = earliest

    for group in collection {
        for item in group.items {
            let today = convertFpDateToDashed(item.date)
            var todayImageList = dayImagesMap[today, default: [ImageInfo]()]
            todayImageList.append(ImageInfo(
                findAPhotoUrl + item.thumbURL, item.createdDate, item.city, item.country, item.sitename))
            dayImagesMap[today] = todayImageList

            var todayCountryNameSet = dayCountryMap[today, default: Set<String>()]
            todayCountryNameSet.insert(item.country)
            dayCountryMap[today] = todayCountryNameSet

            var todayCountryNameMap = dayCountryCitiesMap[today, default: [String:Set<String>]()]
            var todayCityNameSet = todayCountryNameMap[item.country, default: Set<String>()]
            todayCityNameSet.insert(item.city)
            todayCountryNameMap[item.country] = todayCityNameSet
            dayCountryCitiesMap[today] = todayCountryNameMap

            let sites = item.sitename.split(separator: ",")
            if sites.count > 0 {
                var todayCitySiteMap = dayCitySiteMap[today, default: [String:Set<String>]()]
                var todaySiteSet = todayCitySiteMap[item.city, default: Set<String>()]
                for s in sites {
                    todaySiteSet.insert(String(s).trimmingCharacters(in: .whitespacesAndNewlines))
                }
                todayCitySiteMap[item.city] = todaySiteSet
                dayCitySiteMap[today] = todayCitySiteMap
            }

            if item.createdDate < earliest.createdDate {
                earliest = item
            } else if item.createdDate > latest.createdDate {
                latest = item
            }
        }
    }

    var dayCountry = [String:[TripCountry]]()
    for (day, countrySet) in dayCountryMap {
        for country in countrySet {
            let cityList = dayCountryCitiesMap[day]![country]!.map { (cityName) -> TripCity in
                return TripCity(cityName, Array(dayCitySiteMap[day]?[cityName] ?? []).sorted())
            }
            var dayEntry = dayCountry[day, default: [TripCountry]()]
            dayEntry.append(TripCountry(country, cityList))
            dayCountry[day] = dayEntry
        }
    }

    return (tripCountry, dayCountry, dayImagesMap, earliest, latest)
}

func getDetailedHealth(_ hourly: [String:[Health]], _ day: String) -> [Health] {
    var detailed = [Health]()
    for k in hourly.keys {
        if k.hasPrefix(day) {
            detailed += hourly[k]!
        }
    }
    return detailed.sorted { $0.date! < $1.date! }
}

func createTripInfo(_ collection: [FPGroupResponse], _ tlClient: HttpCalls, _ hdClient: HttpCalls, 
                    _ findAPhotoUrl: String, _ dayInfoListVisit: ([DayInfo]) throws -> Void) throws {
    if collection.count < 1 {
        return
    }

    let (tripCountry, dayCountry, dayImages, earliest, latest) = aggregatePhotos(collection, findAPhotoUrl)
    let startTimezone = try getTimezoneId(tlClient, earliest.latitude!, earliest.longitude!)
    let endTimezone = latest.latitude != nil ?
        try getTimezoneId(tlClient, latest.latitude!, latest.longitude!) : startTimezone
    let startString = convertFpDateToDashed(earliest.date)
    let endString = convertFpDateToDashed(latest.date)

    let (tripHealth, dailyHealth, hourlyHealth) = try aggregateHealth(getHealthData(hdClient, startString, endString))

    var allKeySet = Set(dailyHealth.keys)
    allKeySet = allKeySet.union(Set(dayCountry.keys))
    var dayInfo = [DayInfo]()
    for day in allKeySet {
        let detailed = getDetailedHealth(hourlyHealth, day)
        dayInfo.append(DayInfo(
            day,
            (dayCountry[day] ?? []).filter { $0.name.count > 1 },
            (dayImages[day] ?? []).sorted { $0.createdDate < $1.createdDate },
            dailyHealth[day] ?? [],
            detailed))
    }
    dayInfo = dayInfo.sorted { $0.day < $1.day }
    try dayInfoListVisit(dayInfo)

    var tripImages = [ImageInfo]()
    var tripDailyHealth = [Health]()
    for di in dayInfo {
        if di.images.count > 0 {
            tripImages.append(di.images[di.images.count / 2])
        }
        for h in di.health {
            let dh = h
            dh.date = ymdDashedDateFormatter.date(from: di.day)
            tripDailyHealth.append(dh)
        }
    }

    let tripInfo = TripInfo(
        startString,
        earliest.createdDate, startTimezone,
        latest.createdDate, endTimezone,
        tripCountry,
        tripImages,
        tripHealth,
        tripDailyHealth)
    trips.append(tripInfo)
}

func writeDayInfoList(_ outputFolder: String, _ dayInfoList: [DayInfo]) throws {
    let details = TripDailyDetails(dayInfoList)
    let detailsJson = try details.encodeToJson()
    try detailsJson.write(to: URL(fileURLWithPath: "\(outputFolder)/\(dayInfoList[0].day).json"))
}

//-------------------------------------------------------------------------------------------------
let command = Command(usage: "TripGenerator", flags: flags) { flags, args in
    let findAPhotoUrl = flags.getString(name: "findAPhotoUrl")!
    let healthDataUrl = flags.getString(name: "healthDataUrl")!
    let outputFolder = flags.getString(name: "outputFolder")!
    let timezoneLookupUrl = flags.getString(name: "timezoneLookupUrl")!

    do {
        let fpClient = try! HttpCalls.connect(baseUrl: findAPhotoUrl, on: eventGroup).wait()
        defer { fpClient.close() }

        let tlClient = try! HttpCalls.connect(baseUrl: timezoneLookupUrl, on: eventGroup).wait()
        defer { tlClient.close() }

        let hdClient = try! HttpCalls.connect(baseUrl: healthDataUrl, on: eventGroup).wait()
        defer { hdClient.close() }

        var allGroups = [FPGroupResponse]()
        var first = 0
        var totalMatches = 0
        repeat {
            let searchResults = try getFpTripResults(fpClient, first)
            allGroups += searchResults.groups
            first += searchResults.resultCount
            totalMatches = searchResults.totalMatches
        } while first < totalMatches

        let visitDayInfoListWriter: ([DayInfo]) throws -> Void = { dl in
            try writeDayInfoList(outputFolder, dl)
        }


        // Split by gaps (collect those nearby in time)
        var currentCollection = [FPGroupResponse]()
        for idx in 1..<allGroups.count {
            let prev = allGroups[idx - 1]
            currentCollection.append(prev)
            let prevDate = ymdDashedDateFormatter.date(from: prev.name)!
            let cur = allGroups[idx]
            let curDate = ymdDashedDateFormatter.date(from: cur.name)!
            let daysApart = prevDate.timeIntervalSince(curDate) / (24 * 60 * 60)
            if daysApart > 3 {
                try createTripInfo(currentCollection, tlClient, hdClient, findAPhotoUrl, visitDayInfoListWriter)
                currentCollection.removeAll(keepingCapacity: true)
if trips.count == 2 {
    break
}
            }
        }
        try createTripInfo(currentCollection, tlClient, hdClient, findAPhotoUrl, visitDayInfoListWriter)

        let tripsJson = try GeneratedTrips(trips).encodeToJson()
        try tripsJson.write(to: URL(fileURLWithPath: "\(outputFolder)/trips.json"))
    } catch {
        fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
    }
}

command.execute()
