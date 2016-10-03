import XCTest
@testable import LibYAMLSwift

extension YAMLNode: Equatable {}

public func ==(lhs: YAMLNode, rhs: YAMLNode) -> Bool {
    switch (lhs, rhs) {
    case (.scalar(let ls), .scalar(let rs)) where ls == rs: return true
    case (.sequence(let la), .sequence(let ra)):
        guard la.count == ra.count else {
            return false
        }
        
        for i in 0..<la.count {
            if la[i] != ra[i] {
                return false
            }
        }
        return true
    case (.mapping(_), .mapping(_)):
        let ld = lhs.asDictionary, rd = rhs.asDictionary
        guard ld != nil && ld?.count == rd?.count else {
            return false
        }
        
        for (key, value) in ld! {
            if rd![key] != value {
                return false
            }
        }
        return true
    default:
        return false
    }
}

class LibYAMLSwiftTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLoadingYAMLFile() {
        let filepath = Bundle(for: type(of: self)).path(forResource: "demo", ofType: "yaml")!
        let content = try! String(contentsOfFile: filepath)
        let document = try! YAMLDocument(string: content)
        let rootNode = document.rootNode
        
        XCTAssertNotNil(rootNode.asDictionary)
        XCTAssertNil(rootNode.asInt)
    }
    
    func testDumpingYAMLFile() {
        let filepath = Bundle(for: type(of: self)).path(forResource: "demo", ofType: "yaml")!
        let content = try! String(contentsOfFile: filepath)
        let odocument = try! YAMLDocument(string: content)
        
        let tmppath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.yaml")
        tmppath.withUnsafeFileSystemRepresentation {
            odocument.dumpTo(file: $0!)
        }
        let ncontent = try! String(contentsOf: tmppath, encoding: String.Encoding.utf8)
        let ndocument = try! YAMLDocument(string: ncontent)
        
        XCTAssertEqual(odocument.rootNode, ndocument.rootNode)
    }
}
