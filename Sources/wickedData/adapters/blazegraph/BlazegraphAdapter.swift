import Foundation
import FoundationNetworking

public struct BlazegraphAdapter: GraphServiceAdapter {
    public let address: String
    public let port: Int

    public init(address: String = "localhost", port: Int = 9999) {
        self.address = address
        self.port = port
    }

    public func sample<QueryType: Query>(_ query: QueryType) async throws -> Sample<QueryType.BindingType> {
        try await sample(query, timeout: nil)
    }

    public func sample<QueryType: Query>(_ query: QueryType, timeout: Int?) async throws -> Sample<QueryType.BindingType> {
        let stringifiedUrl = "\(url)/blazegraph/namespace/kb/sparql"
        guard let url = URL(string: stringifiedUrl) else {
            throw GraphServiceAdapterError.invalidUrl(stringifiedUrl)
        }
        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = "POST"

        urlRequest.setValue("application/sparql-results+json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "content-type")
        if let unwrappedTimeout = timeout {
            urlRequest.setValue(String(describing: unwrappedTimeout), forHTTPHeaderField: "X-BIGDATA-MAX-QUERY-MILLIS")
        }

        urlRequest.httpBody = "query=\(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)".data(using: .utf8)!
        // print(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)
        // print("query=\(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)")

        let group = DispatchGroup()
        group.enter(1)

        var decoded: Sample<QueryType.BindingType>? = nil
        URLSession.shared.dataTask(
            with: urlRequest, completionHandler: {data, response, error in
                do {
                    decoded = try JSONDecoder().decode(Sample<QueryType.BindingType>.self, from: data!) 
                } catch {
                    print("Unexpected error when decoding blazegraph service response: \(error)")
                }
                group.leave()
            }
        ).resume()

        group.wait()

        return decoded!
    }

    public func update(_ query: UpdateQuery, timeout: Int? = nil) async throws -> UpdateQuery.BindingType {
        let stringifiedUrl = "\(url)/blazegraph/namespace/kb/sparql"
        guard let url = URL(string: stringifiedUrl) else {
            throw GraphServiceAdapterError.invalidUrl(stringifiedUrl)
        }
        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = "POST"

        urlRequest.setValue("application/x-turtle", forHTTPHeaderField: "content-type")
        if let unwrappedTimeout = timeout {
            urlRequest.setValue(String(describing: unwrappedTimeout), forHTTPHeaderField: "X-BIGDATA-MAX-QUERY-MILLIS")
        }

        urlRequest.httpBody = query.text.data(using: .utf8)!

        let group = DispatchGroup()
        group.enter(1)

        var decoded: UpdateQuery.BindingType! = nil

        URLSession.shared.dataTask(
            with: urlRequest, completionHandler: {data, response, error in
                do {
                    decoded = try UpdateQuery.BindingType(String(decoding: data!, as: UTF8.self))
                    // decoded = try JSONDecoder().decode(Sample<QueryType.BindingType>.self, from: data!) 
                } catch {
                    print("Unexpected error when decoding blazegraph service response: \(error)")
                }
                group.leave()
            }
        ).resume()

        group.wait()

        return decoded!
    }
}

