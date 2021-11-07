public enum TripleOperationError: Error {
    case invalidTripleHead(_ value: String)
}

public enum NodeType: CustomStringConvertible {
    case Literal(_ value: String)
    case Entity(_ value: String)

    public var description: String {
        switch self {
        case .Literal(let value):
            return "[\(value)]"
        case .Entity(let value):
            return "(\(value))"
        }
    }

    public var value: String {
        switch self {
        case .Literal(let value):
            return value
        case .Entity(let value):
            return value
        }
    }
}

public enum TripleType {
    case any
    case source
    case target
}

public struct Relationship {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

public struct Triple: CustomStringConvertible{
    public let head: NodeType
    public let relationship: Relationship
    public let tail: NodeType 
    public let type: TripleType

    public init(_ head: NodeType, _ relationship: Relationship, _ tail: NodeType, type: TripleType = .any) throws {
        if case .Literal(let value) = head {
            print("Literal cannot serve as a head of triple")
            throw TripleOperationError.invalidTripleHead(value)
        }
        self.head = head
        self.relationship = relationship
        self.tail = tail
        self.type = type
    }

    public var description: String {
        "\(head) -\(relationship.name)-> \(tail)"
    }
}

