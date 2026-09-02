#!/usr/bin/env bash
# Select Xcode 27 on a GitHub runner.
#
# Xcode 27.0 is the pinned toolchain (beta until ~2026-09-14 GM) and the reason is
# machine/CI parity: the SDK decides which iOS 27 APIs compile, and an unguarded one is
# the single most likely mistake to reach this repo. Building against a different SDK
# than the owner's machine is how that mistake gets through green CI.
#
# The runner image may not carry a beta yet, so fall back rather than hard-failing — but
# annotate the run, because a green check against the wrong SDK proves less than it looks.
set -euo pipefail

want_major=27

candidate=$(ls -d /Applications/Xcode_${want_major}*.app 2>/dev/null | sort -V | tail -1 || true)

if [[ -n "$candidate" ]]; then
    sudo xcode-select -switch "$candidate"
else
    echo "::warning title=Xcode ${want_major} not on this runner::Falling back to $(xcode-select -p). This job is NOT building against the pinned SDK; treat a pass as weaker evidence until the image ships Xcode ${want_major}."
fi

xcodebuild -version
