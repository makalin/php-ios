# php-ios

> Compile PHP to a native iOS Swift Package — a SwiftPM wrapper that embeds a static PHP runtime to enable “serverless” iPhone/iPad apps.

[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](#)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS-blue.svg)](#)
[![PHP](https://img.shields.io/badge/PHP-8.3+-777bb3.svg)](#)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#license)

A Swift Package that vendors a statically-linked PHP runtime (`arm64-apple-ios`) and a tiny bridge so your SwiftUI / UIKit apps can execute bundled PHP scripts fully offline—no servers, no sockets. Great for on-device templating, data transforms, DSLs, migrations, or porting existing PHP logic to iOS.

---

## Features

* 📦 **Zero server**: Run PHP in-process on device (no network).
* 🧱 **Static runtime**: Prebuilt PHP with common extensions (json, pcre, mbstring, tokenizer, xml, dom, libzip).
* 🧩 **Swift bridge**: `PhpEngine` API for `php -r`, script files, argv/env, and JSON IO.
* 🔐 **App-Store friendly**: No downloading executable code; all scripts are bundled.
* 🗂️ **Resources support**: Ship `.php` files via SPM resources.
* 🧪 **Deterministic**: Sandboxed FS with per-app temp and config dirs.
* ⚡ **Fast startup**: Embedded `php.ini` tuned for mobile.

> ✅ **App Store note**: Interpreters are allowed if **all code is bundled** and **no new executable code is downloaded** at runtime (see Apple’s guidelines). This package is designed for that model.

---

## How it works

```
Swift (App)  ──calls──> PhpEngine (Swift)
                         │
                         └── libphp-ios.a (static)
                               └─ executes bundled .php scripts
```

The package exposes `PhpEngine` which bootstraps the embedded PHP CLI entrypoint with an isolated working directory and passes argv/env. STDERR/STDOUT are captured and returned to Swift.

---

## Requirements

* iOS / iPadOS 16.0+
* Xcode 15+
* Swift 5.9+
* PHP scripts compatible with PHP 8.3+

---

## Installation (Swift Package Manager)

**Xcode → Package Dependencies → Add Package**
URL: `https://github.com/makalin/php-ios.git`

Or in `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YourApp",
  platforms: [.iOS(.v16)],
  dependencies: [
    .package(url: "https://github.com/makalin/php-ios.git", from: "0.1.0")
  ],
  targets: [
    .target(
      name: "YourApp",
      dependencies: [.product(name: "PhpIOS", package: "php-ios")],
      resources: [.process("PhpScripts")] // your bundled .php files
    )
  ]
)
```

---

## Quick start

### 1) Add a PHP script

Create `PhpScripts/hello.php` in your app target:

```php
<?php
// PhpScripts/hello.php
$in = stream_get_contents(STDIN);
$payload = json_decode($in, true);
$name = $payload["name"] ?? "World";
echo json_encode(["greeting" => "Hello, $name!", "ts" => time()]);
```

### 2) Call from Swift

```swift
import PhpIOS

let engine = try PhpEngine.shared()

// Run inline code (equiv. to: php -r 'echo json_encode(["ok"=>true]);')
let inline = try engine.runInline("""
echo json_encode(["ok" => true, "php" => PHP_VERSION]);
""")
print(inline.json()?["php"] ?? "n/a")

// Run bundled script and pass JSON via STDIN
let request = ["name": "Mehmet"]
let result = try engine.runScript(
  resource: .init(bundle: .main, path: "PhpScripts/hello.php"),
  stdin: .json(request)
)
let greeting = try result.json()["greeting"] as? String
print(greeting ?? "-")
```

### 3) Using argv / env

```swift
let result = try engine.runScript(
  resource: .init(bundle: .main, path: "PhpScripts/task.php"),
  argv: ["--mode", "migrate"],
  environment: ["APP_ENV": "production"]
)
print(result.stdout) // raw text
```

---

## Swift API surface

```swift
public struct PhpResult {
  public let exitCode: Int32
  public let stdout: String
  public let stderr: String
  public func json() throws -> Any
}

public enum PhpInput {
  case none
  case text(String)
  case data(Data)
  case json(Any) // encodes to UTF-8 JSON
}

public final class PhpEngine {
  public static func shared() throws -> PhpEngine
  public func runInline(_ code: String,
                        stdin: PhpInput = .none,
                        ini: [String:String] = [:]) throws -> PhpResult

  public struct ResourceRef { public let bundle: Bundle; public let path: String }
  public func runScript(resource: ResourceRef,
                        argv: [String] = [],
                        stdin: PhpInput = .none,
                        env: [String:String] = [:],
                        ini: [String:String] = [:]) throws -> PhpResult
}
```

---

## Configuration

* **php.ini overrides**: Pass `ini: ["memory_limit":"64M","display_errors":"0"]`.
* **Working dir**: Defaults to `Library/Caches/phpios`. Use `PhpEngine.configure(paths:)` (optional) to relocate.
* **Extensions**: Built-ins: `json`, `mbstring`, `pcre`, `ctype`, `filter`, `tokenizer`, `xml`, `dom`, `libzip`.
  (See **Building from source** to customize.)

---

## App Store compliance

* Bundle all `.php` files as app resources.
* Do not fetch or execute downloaded scripts or bytecode.
* Do not expose a general “code execution” UI for user-supplied scripts.
* Network use is fine for data, not for executable code.

---

## Examples

* **Templating**: Render Markdown/HTML on device using a PHP library.
* **Migrations**: Run one-shot data transforms for local app storage.
* **Domain logic**: Reuse validated PHP algorithms/DSL parsers offline.
* **Reports**: Generate CSV/JSON from local data sets.

---

## Building from source (optional)

This repo includes:

```
/Toolchain/
  build-php.sh        # cross-compiles PHP 8.3 static for arm64-apple-ios
  sdk/                # minimal headers/libs for iOS
  patches/            # small portability tweaks (iconv, dlopen stubs)
 /Sources/PhpIOS/
  PhpBridge.mm        # calls php_module_main()
  PhpEngine.swift     # public API
  Resources/php.ini   # mobile defaults
  lib/libphp-ios.a    # prebuilt (if not rebuilding)
```

To rebuild:

```bash
cd Toolchain
./build-php.sh --php=8.3.10 --extensions="json,mbstring,xml,dom,zip" --min-ios=16.0
```

Outputs `libphp-ios.a` and headers placed under `Sources/PhpIOS/lib/`.

---

## Sample app (minimal)

```
YourApp/
  Package.swift
  Sources/YourApp/
    App.swift
    ContentView.swift
    PhpScripts/
      hello.php
```

`ContentView.swift`:

```swift
import SwiftUI
import PhpIOS

struct ContentView: View {
  @State private var output = "–"
  var body: some View {
    VStack(spacing: 16) {
      Text("PHP-iOS Demo").font(.title2).bold()
      ScrollView { Text(output).monospaced().frame(maxWidth: .infinity, alignment: .leading) }
      Button("Run PHP") {
        Task {
          do {
            let res = try PhpEngine.shared().runInline(#"echo "Hello from " . PHP_VERSION;"#)
            output = res.stdout
          } catch {
            output = "Error: \(error)"
          }
        }
      }
    }.padding()
  }
}
```

---

## Limitations

* No JIT; Opcache JIT is disabled on iOS.
* FFI, `dl()`, and dynamic loading are disabled.
* Only bundled scripts may run (no code download).
* Long-running tasks should yield; consider chunked processing.

---

## Troubleshooting

* **Dyld errors**: Ensure you’re linking the provided static lib; remove conflicting PHP libs from your project.
* **Missing script**: Verify resource path is included in target and `Package.swift` has `.process("PhpScripts")`.
* **Unicode issues**: Use UTF-8 everywhere; `PhpInput.json` handles encoding.

---

## Roadmap

* Optional SQLite, Intl, GMP builds
* Swift Concurrency helpers (`async`/`await` wrappers)
* SwiftUI sample app
* Composer-style autoloader for bundled libs

---

## Security

* Treat PHP input as untrusted.
* Avoid executing user-provided code.
* Validate/escape all data; prefer JSON IO.

---

## Acknowledgements

* PHP core team
* Mobile cross-compile pioneers in the OSS community

---

## License

MIT © 2025 Mehmet T. AKALIN
