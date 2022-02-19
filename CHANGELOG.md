# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

* Core server functionality has been extracted to a library, [StumpyNIO], now available as a command line tool: [clStumpy]
* Updated server to listen on both IPv6 and IPv4 sockets
* Added UI support for non-standard email clients

## [2.0.2] - 2022-01-23

### Fixed

* UI allows you to get to all the server definitions without resizing the window.

## [2.0.1] - 2022-01-23

### Added

* lots of debugging logging
* Display connection details and mail store details on the server screen

### Fixed

* SMTP now accumulates message data until the termination sequence. [Fixes issue #3](https://github.com/sbeitzel/Stumpy/issues/3)
* POP greeting fixed


## Version [2.0] - 2022-01-19

### Added

* Now requires macOS 12 (Monterey)

### Changed

* Removed the [BlueSocket](https://github.com/Kitura/BlueSocket) dependency and reimplemented the networking code on top of [Swift-NIO](https://github.com/apple/swift-nio) directly


## Version [1.0.1] - 2021-01-13

* Add button to delete an individual server record


## Version [1.0] - 2021-01-11

* Initial release

[Unreleased]: https://github.com/sbeitzel/Stumpy/compare/2.0.2...HEAD
[2.0.2]: https://github.com/sbeitzel/Stumpy/compare/2.01...2.0.2
[2.0.1]: https://github.com/sbeitzel/Stumpy/compare/2.0...2.0.1
[2.0]: https://github.com/sbeitzel/Stumpy/compare/1.0.1...2.0
[1.0.1]: https://github.com/sbeitzel/Stumpy/compare/1.0...1.0.1
[1.0]: https://github.com/sbeitzel/Stumpy/releases/tag/1.0
[StumpyNIO]: https://github.com/sbeitzel/StumpyNIO
[clStumpy]: https://github.com/sbeitzel/clStumpy
