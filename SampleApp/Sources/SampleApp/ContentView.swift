import SwiftUI
import PhpIOS

struct ContentView: View {
    @State private var output = "Welcome to PHP-iOS Demo!\n\nTap 'Run PHP' to execute PHP code on your device."
    @State private var isLoading = false
    @State private var selectedDemo = DemoType.basic
    
    enum DemoType: String, CaseIterable {
        case basic = "Basic PHP"
        case json = "JSON Processing"
        case math = "Math Operations"
        case string = "String Processing"
        case file = "File Operations"
        
        var description: String {
            switch self {
            case .basic: return "Simple PHP echo and variables"
            case .json: return "JSON encoding/decoding"
            case .math: return "Mathematical calculations"
            case .string: return "String manipulation"
            case .file: return "File system operations"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("PHP-iOS Demo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Run PHP scripts natively on iOS")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Demo Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Demo:")
                        .font(.headline)
                    
                    Picker("Demo Type", selection: $selectedDemo) {
                        ForEach(DemoType.allCases, id: \.self) { demo in
                            Text(demo.rawValue).tag(demo)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(selectedDemo.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Output Area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Output:")
                            .font(.headline)
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    ScrollView {
                        Text(output)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 300)
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: runSelectedDemo) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Run PHP")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: clearOutput) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Output")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray4))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func runSelectedDemo() {
        isLoading = true
        
        Task {
            do {
                let result = try await executeDemo(selectedDemo)
                await MainActor.run {
                    output = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    output = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func executeDemo(_ demo: DemoType) async throws -> String {
        let engine = try PhpEngine.shared()
        
        switch demo {
        case .basic:
            return try engine.runInline("""
                echo "Hello from PHP " . PHP_VERSION . "!\n";
                echo "Current time: " . date('Y-m-d H:i:s') . "\n";
                echo "Memory usage: " . memory_get_usage(true) . " bytes\n";
                echo "Platform: " . PHP_OS . "\n";
            """).stdout
            
        case .json:
            let input = ["name": "iOS User", "version": "1.0", "features": ["PHP", "Swift", "Native"]]
            let result = try engine.runInline("""
                $input = json_decode(file_get_contents('php://stdin'), true);
                $response = [
                    'greeting' => 'Hello ' . $input['name'] . '!',
                    'app_version' => $input['version'],
                    'supported_features' => $input['features'],
                    'timestamp' => time(),
                    'php_version' => PHP_VERSION
                ];
                echo json_encode($response, JSON_PRETTY_PRINT);
            """, stdin: .json(input))
            return result.stdout
            
        case .math:
            return try engine.runInline("""
                $numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
                $sum = array_sum($numbers);
                $avg = $sum / count($numbers);
                $max = max($numbers);
                $min = min($numbers);
                
                echo "Numbers: " . implode(', ', $numbers) . "\n";
                echo "Sum: $sum\n";
                echo "Average: " . round($avg, 2) . "\n";
                echo "Max: $max\n";
                echo "Min: $min\n";
                echo "Factorial of 5: " . factorial(5) . "\n";
                
                function factorial($n) {
                    return $n <= 1 ? 1 : $n * factorial($n - 1);
                }
            """).stdout
            
        case .string:
            return try engine.runInline("""
                $text = "Hello World from PHP on iOS!";
                echo "Original: $text\n";
                echo "Uppercase: " . strtoupper($text) . "\n";
                echo "Lowercase: " . strtolower($text) . "\n";
                echo "Word count: " . str_word_count($text) . "\n";
                echo "Character count: " . strlen($text) . "\n";
                echo "Reversed: " . strrev($text) . "\n";
                echo "First 10 chars: " . substr($text, 0, 10) . "\n";
                echo "Last 10 chars: " . substr($text, -10) . "\n";
            """).stdout
            
        case .file:
            return try engine.runInline("""
                echo "File System Information:\n";
                echo "Current directory: " . getcwd() . "\n";
                echo "Temp directory: " . sys_get_temp_dir() . "\n";
                echo "Memory limit: " . ini_get('memory_limit') . "\n";
                echo "Max execution time: " . ini_get('max_execution_time') . " seconds\n";
                echo "PHP SAPI: " . php_sapi_name() . "\n";
                echo "Loaded extensions: " . implode(', ', get_loaded_extensions()) . "\n";
            """).stdout
        }
    }
    
    private func clearOutput() {
        output = "Output cleared.\n\nSelect a demo and tap 'Run PHP' to execute PHP code."
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}