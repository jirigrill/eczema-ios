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

# Pinned like every other tool here, and for the same reason: a linter that gains a rule
# between runs turns an unrelated pull request red for something nobody wrote, and a
# formatter that changes its mind rewrites files the author never touched. Both are
# downloaded into `.tools/` (gitignored) rather than installed with Homebrew, which always
# takes whatever the tap currently holds. Upgrade deliberately, in this file and in CI.
swiftlint_version := "0.65.1"
swiftformat_version := "0.63.0"
tools_dir := ".tools"

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
check: verify-project lint test build

# A moved release tag would otherwise pass silently, which is the whole failure mode the
# pinning exists to prevent. Both are no-ops once the binaries are present at the right
# version, so `just lint` stays fast after the first run.
#
# Fetch the pinned SwiftLint and SwiftFormat into `.tools/`, and assert the pins held.
tools:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{tools_dir}}

    fetch() {
        local name="$1" want="$2" url="$3" archive_member="$4"
        local binary="{{tools_dir}}/$name"

        if [[ -x "$binary" ]] && [[ "$("$binary" --version 2>/dev/null)" == "$want" ]]; then
            return 0
        fi

        echo "==> fetching $name $want"
        local zip
        zip=$(mktemp -t "$name.XXXXXX").zip
        curl --fail --location --silent --show-error "$url" --output "$zip"

        local unpacked
        unpacked=$(mktemp -d -t "$name.XXXXXX")
        unzip -oq "$zip" -d "$unpacked"

        # Copy out by name rather than trusting the archive layout, which differs between
        # the two projects and has changed across releases.
        local found
        found=$(find "$unpacked" -type f -name "$archive_member" -perm -u+x | head -1)
        if [[ -z "$found" ]]; then
            echo "FAIL: $archive_member not found in $url" >&2
            exit 1
        fi
        cp "$found" "$binary"
        chmod +x "$binary"
        rm -rf "$zip" "$unpacked"

        # Assert the pin, so a moved tag cannot pass silently.
        local active
        active=$("$binary" --version)
        if [[ "$active" != "$want" ]]; then
            echo "FAIL: $name pin did not hold; expected $want, got $active." >&2
            exit 1
        fi
        echo "$name $active"
    }

    fetch swiftlint {{swiftlint_version}} \
      "https://github.com/realm/SwiftLint/releases/download/{{swiftlint_version}}/portable_swiftlint.zip" \
      swiftlint
    fetch swiftformat {{swiftformat_version}} \
      "https://github.com/nicklockwood/SwiftFormat/releases/download/{{swiftformat_version}}/swiftformat.zip" \
      swiftformat

# Check formatting and lint. Read-only — fails rather than edits, so it is safe in CI.
lint: tools
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> swiftformat --lint"
    {{tools_dir}}/swiftformat --lint . --reporter github-actions-log
    echo "==> swiftlint"
    {{tools_dir}}/swiftlint lint --strict --quiet

# Run this rather than hand-fixing what `just lint` reports. `swiftformat` runs first
# because SwiftLint's autocorrect can leave layout that the formatter then rewrites.
#
# Apply formatting and every lint fix that can be applied mechanically. Edits files.
fmt: tools
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> swiftformat"
    {{tools_dir}}/swiftformat .
    echo "==> swiftlint --fix"
    {{tools_dir}}/swiftlint lint --fix --quiet
    echo "OK: formatted. Re-run 'just lint' to see what needs a human."

# Opt-in per clone: hooks are not committable, and a hook that appears without being
# asked for is a hook people delete.
#
# Install the pre-commit hook.
install-hooks:
    #!/usr/bin/env bash
    set -euo pipefail
    hook="$(git rev-parse --git-common-dir)/hooks/pre-commit"
    mkdir -p "$(dirname "$hook")"
    cp scripts/hooks/pre-commit "$hook"
    chmod +x "$hook"
    echo "OK: installed $hook"
    echo "Skip it for one commit with 'git commit --no-verify'."

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

# Delete build products. Does not touch the SwiftPM caches or the pinned tools.
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf {{derived_data}}
    for package in {{packages}}; do
        rm -rf "$package/.build"
    done
