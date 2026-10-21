# Bulk Extractor macOS Graphical Application

A modern, standalone macOS graphical application for `bulk_extractor` built with **Swift** and **SwiftUI**.

- **Mac App Repository:** [https://github.com/isoboroff/bulk_extractor](https://github.com/isoboroff/bulk_extractor)
- **Original Codebase:** [https://github.com/simsong/bulk_extractor](https://github.com/simsong/bulk_extractor)

## Features

- **🚀 Interactive Scan Setup:**
  - Drag-and-drop or file/folder browser for forensic disk images (RAW, DMG, E01), files, or directories (`-R`).
  - Output directory selection with automatic directory creation and zap (`-Z`) option.
  - Multi-threaded tuning (`-j`), custom offsets (`-Y`), start page (`-z`), and CLI flag customization.
  - Detailed scanner selector: toggle built-in scanners (`email`, `accts`, `exif`, `find`, `gps`, `gzip`, `json`, `pdf`, `sqlite`, `zip`, etc.).
  - Stop lists (`-w`), alert lists (`-r`), and banner files (`-b`).

- **⚡ Real-Time Scan Progress & Streaming Console:**
  - Real-time progress bar, phase indicators, scan throughput (MB/s), elapsed time, and ETA.
  - Live streamed console logs with search, filtering (errors only), auto-scroll, and one-click copy.
  - Graceful cancellation (`SIGINT`) to ensure DFXML reports and feature files are finalized cleanly.

- **📊 Extracted Features & Results Browser:**
  - Explore generated feature files (`email.txt`, `domain.txt`, `ccn.txt`, `telephone.txt`, `exif.txt`, etc.).
  - Search and filter records with instant search.
  - Export feature records to CSV.
  - Open any prior `bulk_extractor` output directory for inspection.

- **📈 Histograms & Frequency Charts:**
  - Native bar charts (powered by Apple's Charts framework) for frequency histograms (`domain_histogram.txt`, `email_histogram.txt`, etc.).
  - Searchable table of frequencies and values.

- **📑 DFXML Provenance & Report Summary:**
  - Summary of `report.xml`: execution duration, version, total bytes processed, and feature counts.

- **🔍 Forensic Path Inspector (`-p`):**
  - Extract and inspect exact byte sequences, compressed streams, or forensic paths with hexadecimal dumps or raw stream extraction.

- **📦 Standalone Packaging & Dependency Bundling:**
  - Fully self-contained `.app` bundle: packages the `bulk_extractor` binary and relocates all dynamic libraries into `Contents/Frameworks/` using `@rpath`.
  - Zero external dependencies required on target Macs.

---

## Building and Bundling

### Prerequisites

Before building the Mac app, ensure you have:
1. **Xcode and Command Line Tools** with the Swift compiler:
   ```bash
   xcode-select --install
   ```
2. **Core Dependencies (Homebrew)** for building `bulk_extractor`:
   ```bash
   brew install autoconf automake libtool libxml2 libewf exiv2 json-c re2 abseil pkg-config
   ```
   *(Alternatively, run `echo "" | bash etc/CONFIGURE_MACOS.bash` from the repository root).*

3. **Verify the Command-Line Build First:**
   It is recommended to test build and verify the command-line tool from the repository root first:
   ```bash
   ./bootstrap.sh
   ./configure
   make -j
   make check
   ```

### Quick Build (One Command)

From the repository root or `mac_gui` directory, run:

```bash
cd mac_gui
./build_app.sh
```

This will:
1. Ensure the C++ `bulk_extractor` binary is built.
2. Compile the SwiftUI application in Release mode.
3. Assemble the `BulkExtractor.app` bundle in `mac_gui/build/`.
4. Bundle and relocate all dynamic libraries (`.dylib`) into `Contents/Frameworks/`.
5. Code-sign the bundle for macOS.

### Creating a Drag-and-Drop Disk Image (DMG)

To package the built app into a `.dmg` with a drag-and-drop link to `/Applications`:

```bash
cd mac_gui
./create_dmg.sh
```

The resulting `BulkExtractor-2.2.0-macOS.dmg` will be placed in `mac_gui/build/`.

### Running the App

To open the built app directly:

```bash
open mac_gui/build/BulkExtractor.app
```

To install it into your macOS Applications folder:

```bash
cp -R mac_gui/build/BulkExtractor.app /Applications/
```

### Development with SwiftPM / Xcode

You can build and run during development using the Swift Package Manager:

```bash
cd mac_gui
swift run
```

Or open the `mac_gui` folder directly in Xcode:

```bash
xed mac_gui
```
