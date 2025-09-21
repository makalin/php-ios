<?php
// PhpScripts/data-processor.php
// Advanced data processing example

// Read input data
$input = stream_get_contents(STDIN);
$data = json_decode($input, true);

if (!$data) {
    echo json_encode(["error" => "Invalid JSON input"]);
    exit(1);
}

// Process the data
$processed = [
    "original_count" => count($data),
    "processed_at" => date('Y-m-d H:i:s'),
    "summary" => []
];

foreach ($data as $key => $value) {
    if (is_array($value)) {
        $processed["summary"][$key] = [
            "type" => "array",
            "count" => count($value),
            "sample" => array_slice($value, 0, 3)
        ];
    } elseif (is_numeric($value)) {
        $processed["summary"][$key] = [
            "type" => "number",
            "value" => $value,
            "formatted" => number_format($value, 2)
        ];
    } else {
        $processed["summary"][$key] = [
            "type" => "string",
            "length" => strlen($value),
            "preview" => substr($value, 0, 50)
        ];
    }
}

// Add statistics
$processed["statistics"] = [
    "total_items" => count($data),
    "memory_peak" => memory_get_peak_usage(true),
    "execution_time" => microtime(true) - $_SERVER["REQUEST_TIME_FLOAT"]
];

echo json_encode($processed, JSON_PRETTY_PRINT);
?>