#!/usr/bin/env bash

set -euo pipefail

AWS_CLI_REPO="aws-cli"
SLEEP_SECONDS="60"

if [[ ! -d "${AWS_CLI_REPO}/.git" ]]; then
  echo "Error: aws-cli repo not found at ${AWS_CLI_REPO}"
  echo "Clone it first: git clone https://github.com/aws/aws-cli.git"
  exit 1
fi

# Check if a version exists in aws-cli tags
version_exists() {
  local version="${1}"
  git -C "${AWS_CLI_REPO}" tag --list "${version}" | grep -qx "${version}"
}

# Get current version from VERSION file
get_current_version() {
  grep -E '^AWS_CLI_VERSION=' VERSION | sed 's/AWS_CLI_VERSION="//' | sed 's/"$//'
}

# Update VERSION file with new version
update_version_file() {
  local new_version="${1}"
  sed -i.bak "s/^AWS_CLI_VERSION=\"[^\"]*\"/AWS_CLI_VERSION=\"${new_version}\"/" VERSION
  rm VERSION.bak
}

# Commit and push the version change
commit_and_push() {
  local version="${1}"
  git add VERSION
  git commit -m "Update to AWS CLI V2 ${version}"
  git push origin main
}

# Main loop
main() {
  echo "Fetching tags from aws-cli repo..."
  git -C "${AWS_CLI_REPO}" fetch --tags

  local current
  current=$(get_current_version)
  echo "Current version: ${current}"

  IFS='.' read -r major minor patch <<< "${current}"

  while true; do
    # Try incrementing patch
    patch=$((patch + 1))
    local candidate="${major}.${minor}.${patch}"

    if version_exists "${candidate}"; then
      echo "Found version: ${candidate}"
      update_version_file "${candidate}"
      commit_and_push "${candidate}"
      echo "Sleeping ${SLEEP_SECONDS}s before next version..."
      sleep "${SLEEP_SECONDS}"
    else
      # Patch doesn't exist, try next minor
      echo "Version ${candidate} not found, trying next minor..."
      minor=$((minor + 1))
      patch=0
      candidate="${major}.${minor}.${patch}"

      if version_exists "${candidate}"; then
        echo "Found version: ${candidate}"
        update_version_file "${candidate}"
        commit_and_push "${candidate}"
        echo "Sleeping ${SLEEP_SECONDS}s before next version..."
        sleep "${SLEEP_SECONDS}"
      else
        echo "No more versions found after ${current}"
        echo "Last checked: ${candidate}"
        break
      fi
    fi
  done

  echo "Backfill complete"
}

main "$@"
