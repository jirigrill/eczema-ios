# `just` is the sole command interface for this repo. If a command is worth running
# twice, it belongs here — not in a README, and not in an agent's memory.
#
# Never pipe any of this through `xcbeautify`. It is regex-based and fails *silently*:
# lines quietly stop being recognized, so a truncated failure reads as a pass. Read raw
# `xcodebuild` output or the `.xcresult`. `xcbeautify` is for human eyes only.

project := "Eczema.xcodeproj"
scheme := "Eczema"
configuration := "Debug"
derived_data := ".build/DerivedData"

# `generic/platform=iOS Simulator` deliberately pins no runtime or device: it builds
# without booting anything and does not drift when a new simulator is installed.
destination := "generic/platform=iOS Simulator"

# Local package directories, in dependency order.
packages := "Packages/EczemaCore Packages/EczemaUI"

# List the recipes.
default:
    @just --list

# Build the app for the iOS Simulator.
build:
    xcodebuild build \
      -project {{project}} \
      -scheme {{scheme}} \
      -configuration {{configuration}} \
      -destination '{{destination}}' \
      -derivedDataPath {{derived_data}} \
      CODE_SIGNING_ALLOWED=NO

# Run the package tests. No simulator is booted — this is the fast loop.
test:
    #!/usr/bin/env bash
    set -euo pipefail
    for package in {{packages}}; do
        echo "==> swift test $package"
        (cd "$package" && swift test)
    done

# Everything a pull request must pass, in the order that fails cheapest first.
check: verify-project test build

# A source file enumerated in the pbxproj means filesystem synchronization was broken —
# usually by a per-file exclusion or a folder shared between two targets. Both re-introduce
# the file enumeration that synchronized groups exist to remove, and both produce merge
# conflicts on every added file.
#
# Assert the project is still filesystem-synchronized and enumerates no sources.
verify-project:
    #!/usr/bin/env bash
    set -euo pipefail
    pbxproj="{{project}}/project.pbxproj"

    enumerated=$(grep -c 'in Sources' "$pbxproj" || true)
    if [[ "$enumerated" -ne 0 ]]; then
        echo "FAIL: $enumerated source file(s) enumerated in $pbxproj; expected 0." >&2
        grep -n 'in Sources' "$pbxproj" >&2
        exit 1
    fi

    synchronized=$(grep -c fileSystemSynchronized "$pbxproj" || true)
    if [[ "$synchronized" -eq 0 ]]; then
        echo "FAIL: no filesystem-synchronized groups in $pbxproj." >&2
        exit 1
    fi

    echo "OK: 0 enumerated sources, $synchronized filesystem-synchronized reference(s)."

# Delete build products. Does not touch the SwiftPM caches.
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf {{derived_data}}
    for package in {{packages}}; do
        rm -rf "$package/.build"
    done
