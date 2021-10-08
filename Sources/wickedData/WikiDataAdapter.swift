import Foundation
import FoundationNetworking

public protocol GraphServiceAdapter {
    var address: String { get }
    var port: Int { get }
}

public enum GraphServiceAdapterError: Error {
    case invalidUrl(_ url: String)
}

public extension GraphServiceAdapter {
    var url: String {
        "http://\(address):\(port)"
    }
}

public struct Sample<BindingType: Codable>: Codable {
    let head: SampleHead
    let results: SampleBody<BindingType>
}

public struct SampleHead: Codable {
    let vars: [String]
}

public struct SampleBody<BindingType: Codable>: Codable {
    let bindings: [BindingType]
}

public struct Variable: Codable {
    enum CodingKeys: String, CodingKey {
        case language = "xml:lang"
        case type
        case value
    }

    let type: String
    let value: String
    let language: String?
}

public protocol Query {
    associatedtype BindingType: Codable

    var text: String { get }
}

public struct DemoQuery: Query {
    public struct BindingType: Codable {
        let foo: Variable
        let bar: Variable
        let fooLabel: Variable?
        let barLabel: Variable?
    }

    public let text: String
}

public struct WikiDataAdapter: GraphServiceAdapter {
    public let address: String
    public let port: Int

    public func sample<QueryType: Query>(_ query: QueryType) async throws -> Sample<QueryType.BindingType> {
        // sleep(1)
        // print("Fetching...")

        let stringifiedUrl = "\(url)/sparql?query=\(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        guard let url = URL(string: stringifiedUrl) else {
            throw GraphServiceAdapterError.invalidUrl(stringifiedUrl)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/sparql-results+json", forHTTPHeaderField: "accept")


        // print(url)
        // let data = try Data(contentsOf: url)
        let group = DispatchGroup()
        group.enter(1)

        var decoded: Sample<QueryType.BindingType>? = nil
        URLSession.shared.dataTask(
            with: urlRequest, completionHandler: {data, response, error in
                // let decodedData = String(decoding: data!, as: UTF8.self)
                // print(decodedData)
                // let decodedDataObj = try! JSONDecoder().decode(Sample<QueryType.BindingType>.self, from: data!) 
                decoded = try! JSONDecoder().decode(Sample<QueryType.BindingType>.self, from: data!) 
                group.leave()
            }
            ).resume()
        group.wait()

        return decoded!
        //let decodedData = try JSONDecoder().decode(Sample.self, from: data) 
        // print(URLSession.shared.data)
    }
}

