<?php
// PhpScripts/hello.php
// Sample PHP script for iOS

// Read input from STDIN
$input = stream_get_contents(STDIN);
$payload = json_decode($input, true);

// Extract name from payload or use default
$name = $payload["name"] ?? "World";

// Create response
$response = [
    "greeting" => "Hello, $name!",
    "timestamp" => time(),
    "php_version" => PHP_VERSION,
    "platform" => PHP_OS,
    "memory_usage" => memory_get_usage(true)
];

// Output JSON response
echo json_encode($response, JSON_PRETTY_PRINT);
?>