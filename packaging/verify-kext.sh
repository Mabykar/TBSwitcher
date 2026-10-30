#!/bin/bash
# The Apple legacy signature exception depends on the whole original bundle.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
KEXT="${1:?Usage: verify-kext.sh /path/to/DisableTurboBoost.64bits.kext}"
cd "$KEXT"
if [[ -n "$(find . -type l -print)" ]]; then
  echo 'Unexpected symlink in legacy kext.' >&2; exit 1
fi
# Reject additional files as well as missing/modified files.
diff -u <(sed 's/^[^ ]*  //' "$HERE/kext.sha256" | LC_ALL=C sort) \
        <(find . -type f -print | LC_ALL=C sort)
/usr/bin/shasum -a 256 -c "$HERE/kext.sha256"
