import Foundation
import FoundationNetworking

public struct WikiDataAdapter: GraphServiceAdapter {
    public let address: String
    public let port: Int

    public init(address: String = "query.wikidata.org", port: Int = 80) {
        self.address = address
        self.port = port
    }

    public func sample<QueryType: Query>(_ query: QueryType) async throws -> Sample<QueryType.BindingType> {
        let stringifiedUrl = "\(url)/sparql?query=\(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        guard let url = URL(string: stringifiedUrl) else {
            throw GraphServiceAdapterError.invalidUrl(stringifiedUrl)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/sparql-results+json", forHTTPHeaderField: "accept")

        let group = DispatchGroup()
        group.enter(1)

        var decoded: Sample<QueryType.BindingType>? = nil
        URLSession.shared.dataTask(
            with: urlRequest, completionHandler: {data, response, error in
                decoded = try! JSONDecoder().decode(Sample<QueryType.BindingType>.self, from: data!) 
                group.leave()
            }
            ).resume()
        group.wait()

        return decoded!
    }
}

