<?php
// PhpScripts/template-engine.php
// Simple template engine example

// Read template and data from STDIN
$input = stream_get_contents(STDIN);
$payload = json_decode($input, true);

if (!$payload || !isset($payload['template']) || !isset($payload['data'])) {
    echo json_encode(["error" => "Missing template or data"]);
    exit(1);
}

$template = $payload['template'];
$data = $payload['data'];

// Simple template processing
function processTemplate($template, $data) {
    // Replace {{variable}} with data values
    $processed = $template;
    
    foreach ($data as $key => $value) {
        $placeholder = "{{" . $key . "}}";
        $processed = str_replace($placeholder, $value, $processed);
    }
    
    // Handle conditional blocks {{#if condition}}...{{/if}}
    $processed = preg_replace_callback(
        '/\{\{#if\s+(\w+)\}\}(.*?)\{\{\/if\}\}/s',
        function($matches) use ($data) {
            $condition = $matches[1];
            $content = $matches[2];
            
            if (isset($data[$condition]) && $data[$condition]) {
                return $content;
            }
            return '';
        },
        $processed
    );
    
    // Handle loops {{#each array}}...{{/each}}
    $processed = preg_replace_callback(
        '/\{\{#each\s+(\w+)\}\}(.*?)\{\{\/each\}\}/s',
        function($matches) use ($data) {
            $arrayKey = $matches[1];
            $content = $matches[2];
            
            if (isset($data[$arrayKey]) && is_array($data[$arrayKey])) {
                $result = '';
                foreach ($data[$arrayKey] as $item) {
                    $itemContent = $content;
                    if (is_array($item)) {
                        foreach ($item as $itemKey => $itemValue) {
                            $itemContent = str_replace("{{" . $itemKey . "}}", $itemValue, $itemContent);
                        }
                    } else {
                        $itemContent = str_replace("{{.}}", $item, $itemContent);
                    }
                    $result .= $itemContent;
                }
                return $result;
            }
            return '';
        },
        $processed
    );
    
    return $processed;
}

// Process the template
$result = processTemplate($template, $data);

// Return the result
echo json_encode([
    "rendered" => $result,
    "template_length" => strlen($template),
    "data_items" => count($data),
    "processed_at" => date('Y-m-d H:i:s')
], JSON_PRETTY_PRINT);
?>