import Foundation
import LibYAML

public class YAMLDocument {
    private var document: UnsafeMutablePointer<yaml_document_t> = .allocate(capacity: 1)
    private var nodes: [yaml_node_t] {
        let nodes = document.pointee.nodes
        return Array(UnsafeBufferPointer(start: nodes.start, count: nodes.top - nodes.start))
    }
    var rootNode: YAMLNode {
        return YAMLNode(nodes: nodes, node: yaml_document_get_root_node(document).pointee)
    }
    
    public init(string: String) throws {
        var parser: UnsafeMutablePointer<yaml_parser_t> = .allocate(capacity: 1)
        defer { parser.deallocate(capacity: 1) }
        yaml_parser_initialize(parser)
        defer { yaml_parser_delete(parser) }
        
        var bytes = string.utf8.map { UInt8($0) }
        yaml_parser_set_encoding(parser, YAML_UTF8_ENCODING)
        yaml_parser_set_input_string(parser, &bytes, bytes.count-1)
        guard yaml_parser_load(parser, document) == 1 else {
            throw YAMLError(problem: String(validatingUTF8: parser.pointee.problem)!, problemOffset: parser.pointee.problem_offset)
        }
    }
    
    public func dumpTo(file: UnsafePointer<Int8>) {
        let yaml_emitter = UnsafeMutablePointer<yaml_emitter_t>.allocate(capacity: 1)
        yaml_emitter_initialize(yaml_emitter)
        yaml_emitter_set_encoding(yaml_emitter, YAML_UTF8_ENCODING)
        yaml_emitter_open(yaml_emitter)
        
        defer {
            yaml_emitter_close(yaml_emitter)
            yaml_emitter_delete(yaml_emitter)
            yaml_emitter.deallocate(capacity: 1)
        }
        
        var f: UnsafeMutablePointer<FILE>! = nil
        "w".withCString { mode in
            f = fopen(file, mode)
        }
        
        defer {
            fclose(f)
        }
        
        yaml_emitter_set_output_file(yaml_emitter, f)
        dumpWith(emitter: yaml_emitter)
    }
    
    public func dumpTo(file: String) {
        file.withCString {
            dumpTo(file: $0)
        }
    }
    
    private func dumpWith(emitter: UnsafeMutablePointer<yaml_emitter_t>) {
        let document = UnsafeMutablePointer<yaml_document_t>.allocate(capacity: 1)
        yaml_document_initialize(document, nil, nil, nil, 0, 0)
        defer {
            yaml_document_delete(document)
            document.deallocate(capacity: 1)
        }
        
        rootNode.dump(to: document)
        
        yaml_emitter_dump(emitter, document)
    }
    
    deinit {
        yaml_document_delete(document)
        document.deallocate(capacity: 1)
    }
}
