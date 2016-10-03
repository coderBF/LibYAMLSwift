import Foundation
import LibYAML

public indirect enum YAMLNode {
    case scalar(String)
    case mapping([(String,YAMLNode)])
    case sequence([YAMLNode])
}

extension YAMLNode {
    init(nodes: [yaml_node_s], node: yaml_node_s) {
        let newNode: (Int32) -> YAMLNode = { x in YAMLNode(nodes: nodes, node: nodes[x-1]) }
        
        switch node.type {
        case YAML_MAPPING_NODE:
            let pairs = node.data.mapping.pairs
            self = .mapping(UnsafeBufferPointer(start: pairs.start, count: pairs.top - pairs.start).map { pair in
                guard case let .scalar(value) = newNode(pair.key) else { fatalError("Not a scalar key") }
                return (value, newNode(pair.value))
            })
        case YAML_SEQUENCE_NODE:
            let items = node.data.sequence.items
            self = .sequence(UnsafeBufferPointer(start: items.start, count: items.top - items.start).map(newNode))
        case YAML_SCALAR_NODE:
            self = .scalar(String(validatingUTF8: UnsafeRawPointer(node.data.scalar.value)!.assumingMemoryBound(to: CChar.self))!)
        default:
            fatalError("TODO")
        }
    }
    
    init(string: String) throws {
        self = try YAMLDocument(string: string).rootNode
    }
}

extension YAMLNode {
    public var asBool: Bool? {
        switch self {
        case .scalar(s: var s):
            s = s.lowercased()
            return s == "true" ? true : s == "false" ? false : nil
        default:
            return nil
        }
    }
    
    public var asInt: Int? {
        switch self {
        case .scalar(s: let s):
            return Int(s)
        default:
            return nil
        }
    }
    
    public var asDouble: Double? {
        switch self {
        case .scalar(s: let s):
            return Double(s)
        default:
            return nil
        }
    }
    
    public var asString: String? {
        switch self {
        case .scalar(s: let s):
            return s
        default:
            return nil
        }
    }
    
    public var asArray: [YAMLNode]? {
        switch self {
        case .sequence(let nodes):
            return nodes
        default:
            return nil
        }
    }
    
    public var asDictionary: [String: YAMLNode]? {
        switch self {
        case .mapping(let pairs):
            var dict = [String: YAMLNode]()
            for pair in pairs {
                dict[pair.0] = pair.1
            }
            return dict
        default:
            return nil
        }
    }
}


extension YAMLNode {
    @discardableResult
    func dump(to document: UnsafeMutablePointer<yaml_document_t>) -> Int32 {
        var result: Int32 = 0
        switch self {
        case .scalar(let s):
            let len = s.lengthOfBytes(using: String.Encoding.utf8)
            s.withCString { p in
                p.withMemoryRebound(to: yaml_char_t.self, capacity: len) {
                    result = yaml_document_add_scalar(document, nil, $0, Int32(len), YAML_PLAIN_SCALAR_STYLE)
                }
            }
        case .sequence(let array):
            result = yaml_document_add_sequence(document, nil, YAML_ANY_SEQUENCE_STYLE)
            for e in array {
                let index = e.dump(to: document)
                yaml_document_append_sequence_item(document, result, index)
            }
        case .mapping(let dict):
            result = yaml_document_add_mapping(document, nil, YAML_ANY_MAPPING_STYLE)
            for (key, value) in dict {
                let keyIndex = YAMLNode.scalar(key).dump(to: document)
                let valueIndex = value.dump(to: document)
                yaml_document_append_mapping_pair(document, result, keyIndex, valueIndex)
            }
        }
        return result
    }
}
