#!/usr/bin/env bash

set -euo pipefail

AWS_CLI_REPO="aws-cli"
REPO="kube-kaptain/aws-cli-v2-index"
MIN_VERSION="2.15.33"
MAX_VERSION="2.34.0"

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

# Compare two semver strings: returns 0 if $1 <= $2
version_lte() {
  local IFS='.'
  local -a a=($1) b=($2)
  for i in 0 1 2; do
    if (( a[i] < b[i] )); then return 0; fi
    if (( a[i] > b[i] )); then return 1; fi
  done
  return 0
}

fix_release_notes() {
  local version="${1}"

  echo "Fixing ${version}..."

  body=$(gh release view "${version}" --repo "${REPO}" --json body -q '.body' 2>/dev/null) || {
    echo "  SKIP: no release found for ${version}"
    return
  }

  fixed=$(echo "$body" | sed \
    -e "s|${version}/amd\.sha512|${version}/amd-${version}.sha512|g" \
    -e "s|${version}/arm\.sha512|${version}/arm-${version}.sha512|g" \
    -e 's|\${AWS_CLI_VERSION}/amd\.sha512|${AWS_CLI_VERSION}/amd-${AWS_CLI_VERSION}.sha512|g' \
    -e 's|\${AWS_CLI_VERSION}/arm\.sha512|${AWS_CLI_VERSION}/arm-${AWS_CLI_VERSION}.sha512|g' \
    -e 's/aarch6:/aarch64:/g' \
    -e 's/\.zip`/.zip/g')

  if [[ "${body}" == "${fixed}" ]]; then
    echo "  SKIP: no changes needed"
    return
  fi

  gh release edit "${version}" --repo "${REPO}" --notes "${fixed}"
  echo "  DONE"
}

main() {
  echo "Fetching tags from aws-cli repo..."
  git -C "${AWS_CLI_REPO}" fetch --tags

  echo "Fixing release notes from ${MIN_VERSION} to ${MAX_VERSION}..."
  echo ""

  IFS='.' read -r major minor patch <<< "${MIN_VERSION}"

  while true; do
    local candidate="${major}.${minor}.${patch}"

    if ! version_lte "${candidate}" "${MAX_VERSION}"; then
      break
    fi

    if version_exists "${candidate}"; then
      fix_release_notes "${candidate}"
      patch=$((patch + 1))
    else
      # Patch doesn't exist, try next minor
      minor=$((minor + 1))
      patch=0
      candidate="${major}.${minor}.${patch}"

      if ! version_lte "${candidate}" "${MAX_VERSION}"; then
        break
      fi

      if ! version_exists "${candidate}"; then
        echo "No more versions found after ${major}.$((minor - 1)).x"
        break
      fi
    fi
  done

  echo ""
  echo "Complete."
}

main "$@"
