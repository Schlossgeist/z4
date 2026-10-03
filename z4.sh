#!/usr/bin/env bash

# Z4 build system entry point
# At the moment, this just passes everything through to the central `zig build`.
# In the future, every preprocessing step will be orchestrated by this script,
# e.g. manifest generation, etc.

cd .. && zig build "$@"
