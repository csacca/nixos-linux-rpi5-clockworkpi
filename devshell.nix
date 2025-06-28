{pkgs, ...}: let
  getLatestGreenCommit = pkgs.writeShellScriptBin "get-latest-green-commit" ''
    #!/usr/bin/env bash
    # get-upstream-green-commit  (or whatever name you settle on)
    # Prints SHA, first-line commit message, and finish time of the latest
    # successful “Pi kernel build tests” run on branch rpi-6.12.y.

    set -euo pipefail

    REPO="ak-rex/ClockworkPi-linux"
    BRANCH="rpi-6.12.y"
    WORKFLOW="Pi kernel build tests"

    # Ensure GitHub CLI is authenticated
    if ! gh auth status >/dev/null 2>&1; then
      echo "❌  GitHub CLI not authenticated."
      echo "   Run 'gh auth login' or export GITHUB_TOKEN with actions:read scope."
      exit 1
    fi

    # 1) Get the newest successful run (we only need headSha and updatedAt here)
    read -r SHA FINISHED <<<"$(gh run list \
        --repo "$REPO" \
        --workflow "$WORKFLOW" \
        --branch "$BRANCH" \
        --json headSha,conclusion,updatedAt \
        --limit 20 |                                # grab a handful, newest first
      jq -r '
          map(select(.conclusion=="success"))       # keep only “green” runs
          | first                                   # newest green
          | "\(.headSha) \(.updatedAt)"
      ')"

    if [[ -z "$SHA" ]]; then
      echo "⚠️  No successful runs found."
      exit 2
    fi

    # 2) Fetch the commit message for that SHA
    MESSAGE=$(gh api "/repos/$REPO/commits/$SHA" --jq '.commit.message' | head -n1)

    printf "✅  Latest green commit:\n"
    printf "SHA:      %s\n"  "$SHA"
    printf "Message:  %s\n"  "$MESSAGE"
    printf "Finished: %s\n"  "$FINISHED"
  '';
in
  pkgs.mkShell {
    name = "clockworkpi-dev-gh";

    # Anything here ends up on PATH inside `nix develop`
    packages = [
      pkgs.gh # GitHub CLI
      pkgs.jq # JSON filter
      getLatestGreenCommit
    ];

    shellHook = ''
    '';
  }
