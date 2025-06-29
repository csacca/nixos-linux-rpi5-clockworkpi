{pkgs, ...}: let
  # ───────────── 1. get-latest-green-commit ─────────────
  getLatestGreenCommit = pkgs.writeShellScriptBin "get-latest-green-commit" ''
    #!/usr/bin/env bash
    set -euo pipefail

    QUIET=0
    if [ "$#" -ge 1 ] && [ "$1" = "--quiet" ]; then
      QUIET=1
      shift
    fi

    REPO="ak-rex/ClockworkPi-linux"
    BRANCH="rpi-6.12.y"
    WORKFLOW="Pi kernel build tests"

    if ! gh auth status &>/dev/null; then
      echo "❌  GitHub CLI not authenticated.  Run 'gh auth login'." >&2
      exit 1
    fi

    # newest successful run ⇒ SHA + finish time
    read -r SHA FINISHED <<<"$(gh run list \
      --repo "$REPO" \
      --workflow "$WORKFLOW" \
      --branch "$BRANCH" \
      --json headSha,conclusion,updatedAt \
      --limit 20 | jq -r '
        map(select(.conclusion=="success")) | first |
        "\(.headSha) \(.updatedAt)"
      ' )"

    [ -z "$SHA" ] && { echo "No successful runs found." >&2; exit 2; }

    if [ "$QUIET" -eq 1 ]; then
      echo "$SHA"
      exit 0
    fi

    MESSAGE=$(gh api "/repos/$REPO/commits/$SHA" \
               --jq '.commit.message' | head -n1)

    printf "✅  Latest green commit:\n"
    printf "SHA:      %s\n" "$SHA"
    printf "Message:  %s\n" "$MESSAGE"
    printf "Finished: %s\n" "$FINISHED"
  '';

  # ───────────── 2. update-clockworkpi-kernel ─────────────
  updateKernel = pkgs.writeShellScriptBin "update-clockworkpi-kernel" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # refuse if uncommitted changes
    if ! git diff --quiet HEAD -- flake.nix flake.lock; then
      echo "❌  Uncommitted changes detected in flake.nix or flake.lock."
      echo "    Please commit or stash before running this script."
      exit 1
    fi

    NEW_SHA=$(get-latest-green-commit --quiet)
    CURRENT_SHA=$(sed -nE 's|.*url = "github:ak-rex/ClockworkPi-linux/([^"]+)".*|\1|p' flake.nix)

    echo "📌  currently pinned: $CURRENT_SHA"
    echo "🆕  latest passing : $NEW_SHA"

    if [ "$NEW_SHA" = "$CURRENT_SHA" ]; then
      echo "👍  already up-to-date"
      exit 0
    fi

    echo "🔄  updating flake.nix …"
    sed -i -E \
      "s|(url = \"github:ak-rex/ClockworkPi-linux/)[^\"]+\"|\1$NEW_SHA\"|" \
      flake.nix

    echo "🔄  updating flake.lock …"
    nix flake update clockworkPiLinux

    git add flake.nix flake.lock
    COMMIT_MSG="kernel: bump ClockworkPi-linux to $NEW_SHA"
    git commit -m "$COMMIT_MSG"

    echo "✅  flake.nix & flake.lock updated & committed."
  '';
in
  pkgs.mkShell {
    name = "clockworkpi-dev";

    packages = [
      pkgs.gh # GitHub CLI
      pkgs.jq # JSON filter
      pkgs.git # for commit step
      getLatestGreenCommit
      updateKernel
    ];

    shellHook = ''
      echo "Run 'get-latest-green-commit' or 'update-clockworkpi-kernel'"
    '';
  }
