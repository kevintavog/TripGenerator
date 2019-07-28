import Foundation

import HTTP
import SwiftyJSON

public class HttpCalls {
    private let httpClient: HTTPClient
    private let worker: Worker
    private let pathPrefix: String

    static public func connect(baseUrl: String, on worker: Worker) -> Future<HttpCalls> {
        let clientPromise = worker.eventLoop.newPromise(HttpCalls.self)
        let url = URLRequest(url: URL(string: baseUrl)!)
        HTTPClient.connect(hostname: url.url!.host!, port: url.url!.port ?? 80, on: worker) { error in
            clientPromise.fail(error: error)
        }.do() { client in
            let calls = HttpCalls(client: client, worker: worker, pathPrefix: url.url!.path)
            clientPromise.succeed(result: calls)
        }.catch { error in
            clientPromise.fail(error: error)
        }
        return clientPromise.futureResult
    }

    private init(client: HTTPClient, worker: Worker, pathPrefix: String) {
        self.httpClient = client
        self.worker = worker
        self.pathPrefix = pathPrefix
    }

    public func close() {
        self.httpClient.close().do() {
        }.catch() { error in
            print("Error closing HttpCalls http client: \(error)")
        }
    }

    public func getJson(path: String) -> Future<JSON?> {
        return self.get(path: path).map(to: JSON?.self) { data in
            if let d = data {
                return try JSON(data: d)
            }
            return nil
        }
    }

    public func get(path: String) -> Future<Data?> {
        let request = HTTPRequest(method: .GET, url: self.pathPrefix + path)
        return httpClient.send(request).map(to: Data?.self) { response in
            if response.status.code >= 400 {
                let body = String(data: response.body.data ?? Data(), encoding: .utf8) ?? ""
                throw TGError.httpError(status: response.status.code, message: body)
            }
            return response.body.data
        }
    }

    public func putJson(path: String, body: Data) -> Future<JSON?> {
        return self.put(path: path, body: body).map(to: JSON?.self) { data in
            if let d = data {
                return try JSON(data: d)
            }
            return nil
        }
    }

    public func put(path: String, body: Data) -> Future<Data?> {
        let request = HTTPRequest(method: .PUT, url: self.pathPrefix + path, body: HTTPBody(data: body))
        return httpClient.send(request).map(to: Data?.self) { response in
            if response.status.code >= 400 {
                let body = String(data: response.body.data ?? Data(), encoding: .utf8) ?? ""
                throw TGError.httpError(status: response.status.code, message: body)
            }
            return response.body.data
        }
    }

    public func postJson(path: String, body: Data) -> Future<JSON?> {
        return self.post(path: path, body: body).map(to: JSON?.self) { data in
            if let d = data {
                return try JSON(data: d)
            }
            return nil
        }
    }

    public func post(path: String, body: Data) -> Future<Data?> {
        let request = HTTPRequest(method: .POST, url: self.pathPrefix + path, body: HTTPBody(data: body))
        return httpClient.send(request).map(to: Data?.self) { response in
            if response.status.code >= 400 {
                let body = String(data: response.body.data ?? Data(), encoding: .utf8) ?? ""
                throw TGError.httpError(status: response.status.code, message: body)
            }
            return response.body.data
        }
    }
}
