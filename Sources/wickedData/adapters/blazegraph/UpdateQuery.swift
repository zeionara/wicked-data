import Foundation

public enum UpdateQueryExecutionError: Error {
    case cannotDecodeResponse(message: String)
}

public struct UpdateQuery: Query {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public struct BindingType: Codable, CustomStringConvertible {
        private static let xmlRegex = try! NSRegularExpression(
            pattern: #"<\?xml version="1.0"\?><data modified="(?<nModifiedTriples>[0-9]+)" milliseconds="(?<executionTimeInMilliseconds>[0-9]+)"/>"#,
            // pattern: "<?xml version=\"1.0\"?><data modified=\"(?<nModifiedTriples>[0-9]+)\" milliseconds=\"(?<executionTimeInMilliseconds>[0-9]+)\"/>",
            options: []
        )

        public let nModifiedTriples: Int
        public let executionTimeInMilliseconds: Int 

        public init(_ xml: String) throws {
            // print(xml)
            // 
            // let fooRegexp = try! NSRegularExpression(
            //     pattern: #"<?xml version="1.0"\?><data modified="(?<nModifiedTriples>[0-9]+)""#,
            //     // pattern: "<?xml version=\"1.0\"?><data modified=\"(?<nModifiedTriples>[0-9]+)\" milliseconds=\"(?<executionTimeInMilliseconds>[0-9]+)\"/>",
            //     options: []
            // )

            // let foo = #"<?xml version="1.0"?><data modified="12""#
            // print(fooRegexp.matches(in: foo, options: [], range: NSRange(foo.startIndex..<foo.endIndex, in: foo)).count)

            let xmlRange = NSRange(
                xml.startIndex..<xml.endIndex,
                in: xml
            )   

            let matches = BindingType.xmlRegex.matches(
                in: xml,
                options: [],
                range: xmlRange
            )    

            guard let match = matches.first else {
                throw UpdateQueryExecutionError.cannotDecodeResponse(message: "Reponse does not satisfy the reference string")
            }

            // Decode nModifiedTriples

            let nModifiedTriplesRangeInMatch = match.range(withName: "nModifiedTriples")
            if let nModifiedTriplesRangeInString = Range(nModifiedTriplesRangeInMatch, in: xml) {
                nModifiedTriples = String(xml[nModifiedTriplesRangeInString]).asInt
            } else {
                throw UpdateQueryExecutionError.cannotDecodeResponse(message: "Cannot extract number of modified triples")
            }

            let execitionTimeInMillisecondsRangeInMatch = match.range(withName: "executionTimeInMilliseconds")
            if let execitionTimeInMillisecondsRangeInString = Range(execitionTimeInMillisecondsRangeInMatch, in: xml) {
                executionTimeInMilliseconds = String(xml[execitionTimeInMillisecondsRangeInString]).asInt
            } else {
                throw UpdateQueryExecutionError.cannotDecodeResponse(message: "Cannot extract execution time in milliseconds")
            }
        }

        public var description: String {
            "Inserted \(nModifiedTriples) in \(executionTimeInMilliseconds) ms"
        }
    }
}

