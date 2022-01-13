import Foundation
import FoundationNetworking
import Logging

public let NSEC_PER_SEC: Int = 1_000_000_000

fileprivate extension Optional where Wrapped == Logger {
    func error(_ message: String) {
        if let logger = self {
            logger.error(Logger.Message(stringLiteral: message))
        } else {
            print(message)
        }
    }

    func info(_ message: String) {
        if let logger = self {
            logger.info(Logger.Message(stringLiteral: message))
        } else {
            print(message)
        }
    }

    func trace(_ message: String) {
        if let logger = self {
            logger.trace(Logger.Message(stringLiteral: message))
        } else {
            print(message)
        }
    }
}

public enum DataDecodingError: Error {
    case emptyResponse(String)
    case cannotDecodeSample
}

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

    public enum URLPrefix: String {
        case blazegraph, bigdata
    }

    public func sample<QueryType: Query>(_ query: QueryType, timeout: Int?, prefix: URLPrefix = .bigdata, maxNWastedAttempts: Int = 0, delay: Double = 1, logger: Logger? = nil) async throws -> Sample<QueryType.BindingType> {
        let stringifiedUrl = "\(url)/\(prefix.rawValue)/namespace/kb/sparql"
        guard let url = URL(string: stringifiedUrl) else {
            throw GraphServiceAdapterError.invalidUrl(stringifiedUrl)
        }
        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = "POST"

        urlRequest.setValue("application/sparql-results+json", forHTTPHeaderField: "accept")
        urlRequest.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "content-type")
        if let unwrappedTimeout = timeout {
            urlRequest.timeoutInterval = Double(unwrappedTimeout) / 1000.0
            urlRequest.setValue(String(describing: unwrappedTimeout), forHTTPHeaderField: "X-BIGDATA-MAX-QUERY-MILLIS")
        }

        urlRequest.httpBody = "query=\(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)".data(using: .utf8)!
        // print(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)
        // print("query=\(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)")

        let group = DispatchGroup()

        var decoded: Sample<QueryType.BindingType>? = nil
        var caughtException: Bool = false
        var nWastedAttempts: Int = 0
        var isSuccessful: Bool = false
        var currentDelay = delay

        // print("Initial delay = \(currentDelay)")

        while true {
            group.enter(1)

            URLSession.shared.dataTask(
                with: urlRequest, completionHandler: {data, response, error in
                    do {
                        if let unwrappedData = data {
                            decoded = try JSONDecoder().decode(Sample<QueryType.BindingType>.self, from: unwrappedData)
                        } else {
                            throw DataDecodingError.emptyResponse(String(describing: error))
                        }
                        isSuccessful = true
                        if caughtException {
                            caughtException = false
                        }
                    } catch {
                        logger.trace("Foo Unexpected error when decoding blazegraph service response: \(error)")
                        logger.trace("Response: ")
                        logger.trace(String(describing: response))
                        if let unwrappedData = data {
                            logger.trace("Response body: ")
                            logger.trace(String(decoding: unwrappedData, as: UTF8.self))
                        } else {
                            logger.trace("No response body")
                        }
                        caughtException = true
                        // throw error
                        nWastedAttempts += 1
                    }

                    group.leave()
                }
            ).resume()

            group.wait()

            if (nWastedAttempts > 0) {
                logger.trace("Wasted attempts : \(nWastedAttempts) / \(maxNWastedAttempts)")
            }

            if (isSuccessful || !isSuccessful && nWastedAttempts > maxNWastedAttempts) {
                break
            } else if (!isSuccessful && nWastedAttempts <= maxNWastedAttempts) {
                logger.trace("Trying again after \(currentDelay) seconds")
                await Task.sleep(UInt64(currentDelay * Double(NSEC_PER_SEC)))
                currentDelay *= 2
            }
        }

        if !caughtException, let decodedUnwrapped = decoded {
            return decodedUnwrapped
        }

        throw DataDecodingError.cannotDecodeSample
    }

    public func insert(_ query: InsertQuery, timeout: Int? = nil, prefix: URLPrefix = .bigdata) async throws -> InsertQuery.BindingType {
        let stringifiedUrl = "\(url)/\(prefix.rawValue)/namespace/kb/sparql"
        guard let url = URL(string: stringifiedUrl) else {
            throw GraphServiceAdapterError.invalidUrl(stringifiedUrl)
        }
        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = "POST"

        urlRequest.setValue("application/x-turtle", forHTTPHeaderField: "content-type")
        if let unwrappedTimeout = timeout {
            urlRequest.timeoutInterval = Double(unwrappedTimeout) / 1000.0
            urlRequest.setValue(String(describing: unwrappedTimeout), forHTTPHeaderField: "X-BIGDATA-MAX-QUERY-MILLIS")
        }

        urlRequest.httpBody = query.text.data(using: .utf8)!

        let group = DispatchGroup()
        group.enter(1)

        var decoded: InsertQuery.BindingType! = nil

        URLSession.shared.dataTask(
            with: urlRequest, completionHandler: {data, response, error in
                do {
                    decoded = try InsertQuery.BindingType(String(decoding: data!, as: UTF8.self))
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

    public func update(_ query: UpdateQuery, timeout: Int? = nil, prefix: URLPrefix = .bigdata) async throws -> UpdateQuery.BindingType {
        let stringifiedUrl = "\(url)/\(prefix.rawValue)/namespace/kb/sparql"
        guard let url = URL(string: stringifiedUrl) else {
            throw GraphServiceAdapterError.invalidUrl(stringifiedUrl)
        }
        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = "POST"

        urlRequest.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "content-type")
        if let unwrappedTimeout = timeout {
            urlRequest.timeoutInterval = Double(unwrappedTimeout) / 1000.0
            urlRequest.setValue(String(describing: unwrappedTimeout), forHTTPHeaderField: "X-BIGDATA-MAX-QUERY-MILLIS")
        }

        // urlRequest.httpBody = query.text.data(using: .utf8)!
        urlRequest.httpBody = "update=\(query.text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)".data(using: .utf8)!

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

    public func clear(timeout: Int? = nil, prefix: URLPrefix = .bigdata) async throws -> UpdateQuery.BindingType {
        try await update(
            UpdateQuery(
                text: "delete {?h ?r ?t} where {?h ?r ?t}"
            ),
            timeout: timeout,
            prefix: prefix
        )
    }
}

