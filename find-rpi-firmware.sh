#!/usr/bin/env bash
#
#  find-rpi-firmware.sh
#
#  REQUIREMENTS: git ≥ 2.30, bash, a few × 100 MB free in TMPDIR
#
#  EXAMPLE
#    ./find-rpi-firmware.sh \
#        --kernel-repo  https://github.com/ak-rex/ClockworkPi-linux.git \
#        --kernel-sha   59b5c72214c967316b6de5916ef2ee63a17baee1
#
set -euo pipefail

### --- CLI parsing --------------------------------------------------------
KERNEL_REPO=
KERNEL_SHA=
UPSTREAM_REPO=https://github.com/raspberrypi/linux.git
UPSTREAM_BRANCH=rpi-6.12.y

while [[ $# -gt 0 ]]; do
  case $1 in
    --kernel-repo)    KERNEL_REPO=$2;  shift 2 ;;
    --kernel-sha)     KERNEL_SHA=$2;   shift 2 ;;
    --upstream-repo)  UPSTREAM_REPO=$2;shift 2 ;;
    --upstream-branch)UPSTREAM_BRANCH=$2;shift 2 ;;
    -h|--help)
      echo "usage: $0 --kernel-repo URL --kernel-sha SHA [options]" ; exit 0 ;;
    *) echo "unknown flag $1" >&2 ; exit 1 ;;
  esac
done

[[ -z $KERNEL_REPO || -z $KERNEL_SHA ]] && {
  echo "❌  --kernel-repo and --kernel-sha are required" >&2; exit 1; }

### --- create a *tiny* bare clone of the kernel repo ----------------------
K_TMP=$(mktemp -d -t krepo.XXXX)
git clone --bare --filter=blob:none --quiet "$KERNEL_REPO" "$K_TMP"

# fetch the single commit we care about (plus its parents)
git --git-dir="$K_TMP" fetch --filter=blob:none --quiet origin "$KERNEL_SHA"

# add + fetch the upstream branch for merge-base computation
git --git-dir="$K_TMP" remote add upstream "$UPSTREAM_REPO" 2>/dev/null || true
git --git-dir="$K_TMP" fetch --filter=blob:none --quiet upstream "$UPSTREAM_BRANCH"

# resolve SHAs
K_COMMIT=$(git --git-dir="$K_TMP" rev-parse "$KERNEL_SHA")
U_COMMIT=$(git --git-dir="$K_TMP" rev-parse "upstream/$UPSTREAM_BRANCH")
MB_COMMIT=$(git --git-dir="$K_TMP" merge-base "$K_COMMIT" "$U_COMMIT")

### --- clone raspberrypi/firmware very shallowly -------------------------
FW_TMP=$(mktemp -d -t fwbare.XXXX)
git clone --bare --filter=blob:none --quiet \
  https://github.com/raspberrypi/firmware.git "$FW_TMP"

find_fw () {
  git --git-dir="$FW_TMP" -c core.commitGraph=false \
      log -1 --format=%H -G "^$1$" -- extra/git_hash 2>/dev/null || true
}

FW_SHA=$(find_fw "$K_COMMIT")
if [[ -z $FW_SHA ]]; then
  echo "kernel tip not built on Pi farm – trying merge-base $MB_COMMIT"
  FW_SHA=$(find_fw "$MB_COMMIT")
fi

if [[ -z $FW_SHA ]]; then
  echo "❌  No matching firmware revision found" >&2; exit 1
fi

printf "✅  firmware commit = %s\n" "$FW_SHA"
