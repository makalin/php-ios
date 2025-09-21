import XCTest
@testable import PhpIOS

final class PhpEngineTests: XCTestCase {
    
    var engine: PhpEngine!
    
    override func setUp() {
        super.setUp()
        do {
            engine = try PhpEngine.shared()
        } catch {
            XCTFail("Failed to initialize PHP engine: \(error)")
        }
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    func testBasicPHPExecution() throws {
        let result = try engine.runInline("echo 'Hello, World!';")
        
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.contains("Hello, World!"))
        XCTAssertTrue(result.stderr.isEmpty)
    }
    
    func testPHPVersion() throws {
        let result = try engine.runInline("echo PHP_VERSION;")
        
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertFalse(result.stdout.isEmpty)
        XCTAssertTrue(result.stdout.contains("8."))
    }
    
    func testJSONInput() throws {
        let input: [String: Any] = ["name": "Test", "value": 42]
        let result = try engine.runInline("""
            $data = json_decode(file_get_contents('php://stdin'), true);
            echo json_encode(['received' => $data['name'], 'number' => $data['value']]);
        """, stdin: .json(input))
        
        XCTAssertEqual(result.exitCode, 0)
        
        let json = try result.json() as? [String: Any]
        XCTAssertEqual(json?["received"] as? String, "Test")
        XCTAssertEqual(json?["number"] as? Int, 42)
    }
    
    func testTextInput() throws {
        let input = "Hello from Swift!"
        let result = try engine.runInline("""
            $input = file_get_contents('php://stdin');
            echo 'Received: ' . $input;
        """, stdin: .text(input))
        
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.contains("Received: Hello from Swift!"))
    }
    
    func testDataInput() throws {
        let data = "Test data".data(using: .utf8)!
        let result = try engine.runInline("""
            $data = file_get_contents('php://stdin');
            echo 'Data length: ' . strlen($data);
        """, stdin: .data(data))
        
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.contains("Data length: 9"))
    }
    
    func testMathOperations() throws {
        let result = try engine.runInline("""
            $numbers = [1, 2, 3, 4, 5];
            $sum = array_sum($numbers);
            $avg = $sum / count($numbers);
            echo json_encode(['sum' => $sum, 'average' => $avg]);
        """)
        
        XCTAssertEqual(result.exitCode, 0)
        
        let json = try result.json() as? [String: Any]
        XCTAssertEqual(json?["sum"] as? Int, 15)
        XCTAssertEqual(json?["average"] as? Double, 3.0)
    }
    
    func testStringOperations() throws {
        let result = try engine.runInline("""
            $text = 'Hello World';
            $operations = [
                'original' => $text,
                'uppercase' => strtoupper($text),
                'lowercase' => strtolower($text),
                'length' => strlen($text),
                'words' => str_word_count($text)
            ];
            echo json_encode($operations);
        """)
        
        XCTAssertEqual(result.exitCode, 0)
        
        let json = try result.json() as? [String: Any]
        XCTAssertEqual(json?["original"] as? String, "Hello World")
        XCTAssertEqual(json?["uppercase"] as? String, "HELLO WORLD")
        XCTAssertEqual(json?["lowercase"] as? String, "hello world")
        XCTAssertEqual(json?["length"] as? Int, 11)
        XCTAssertEqual(json?["words"] as? Int, 2)
    }
    
    func testErrorHandling() throws {
        let result = try engine.runInline("""
            trigger_error('Test error', E_USER_ERROR);
        """)
        
        // Should still execute but with error
        XCTAssertNotNil(result)
        XCTAssertFalse(result.stderr.isEmpty)
    }
    
    func testMemoryUsage() throws {
        let result = try engine.runInline("""
            $memory = memory_get_usage(true);
            echo json_encode(['memory' => $memory]);
        """)
        
        XCTAssertEqual(result.exitCode, 0)
        
        let json = try result.json() as? [String: Any]
        let memory = json?["memory"] as? Int
        XCTAssertNotNil(memory)
        XCTAssertGreaterThan(memory!, 0)
    }
    
    func testConvenienceMethods() throws {
        struct TestData: Codable {
            let name: String
            let value: Int
        }
        
        let input = TestData(name: "Test", value: 42)
        let result = try engine.processJSON(input, with: """
            $data = json_decode(file_get_contents('php://stdin'), true);
            echo json_encode(['processed' => $data['name'], 'doubled' => $data['value'] * 2]);
        """)
        
        let json = result as? [String: Any]
        XCTAssertEqual(json?["processed"] as? String, "Test")
        XCTAssertEqual(json?["doubled"] as? Int, 84)
    }
    
    func testTextProcessing() throws {
        let input = "Hello World"
        let result = try engine.processText(input, with: """
            $text = file_get_contents('php://stdin');
            echo strtoupper($text);
        """)
        
        XCTAssertEqual(result, "HELLO WORLD")
    }
}