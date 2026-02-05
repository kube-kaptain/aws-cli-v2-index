#!/usr/bin/env bash

set -euo pipefail

if [ -z "${OUTPUT_SUB_PATH:-}" ]; then
  echo "OUTPUT_SUB_PATH must be set!"
  exit 1
fi

rm -rf "${OUTPUT_SUB_PATH}"
mkdir -p "${OUTPUT_SUB_PATH}"

# 1. Config
echo "Pulling configuration from repo root VERSION file..."
source VERSION
echo "AWS CLI version target is '${AWS_CLI_VERSION}'."
echo

# 2. Define Resources
echo "Download and tag links are..."
AMD_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip"
ARM_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64-${AWS_CLI_VERSION}.zip"
AWS_TAG_URL="https://github.com/aws/aws-cli/releases/tag/${AWS_CLI_VERSION}"
echo "AMD URL: ${AMD_URL}"
echo "ARM URL: ${ARM_URL}"
echo "Tag URL: ${AWS_TAG_URL}"
echo

# 3. Process x86_64 (AMD)
echo "Verifying AMD64 version '${AWS_CLI_VERSION}'..."
curl -sL "${AMD_URL}" -o "${OUTPUT_SUB_PATH}/awscli-amd.zip"
AMD_SHA512=$(sha512sum "${OUTPUT_SUB_PATH}/awscli-amd.zip" | awk '{print $1}')
echo "SHA512 is ${AMD_SHA512}"
echo "Unzipping and native execution to check version..."
unzip -q "${OUTPUT_SUB_PATH}/awscli-amd.zip" -d "${OUTPUT_SUB_PATH}/check_amd"
"${OUTPUT_SUB_PATH}/check_amd/aws/dist/aws" --version | grep -q "${AWS_CLI_VERSION}"
echo

# 4. Process aarch64 (ARM)
echo "Verifying ARM64 version '${AWS_CLI_VERSION}'..."
curl -sL "${ARM_URL}" -o "${OUTPUT_SUB_PATH}/awscli-arm.zip"
ARM_SHA512=$(sha512sum "${OUTPUT_SUB_PATH}/awscli-arm.zip" | awk '{print $1}')
echo "SHA512 is ${ARM_SHA512}"
echo "Unzipping and verifying ARM64 binary architecture..."
unzip -q "${OUTPUT_SUB_PATH}/awscli-arm.zip" -d "${OUTPUT_SUB_PATH}/check_arm"
file "${OUTPUT_SUB_PATH}/check_arm/aws/dist/aws" | grep -q "aarch64"
echo

# 5. Generate Artifacts
echo "Generating GH release artifacts..."
echo "${AMD_URL}" > "${OUTPUT_SUB_PATH}/amd.url"
echo "${AMD_SHA512}" > "${OUTPUT_SUB_PATH}/amd.sha512"
echo "${ARM_URL}" > "${OUTPUT_SUB_PATH}/arm.url"
echo "${ARM_SHA512}" > "${OUTPUT_SUB_PATH}/arm.sha512"
echo
echo "Generating release notes..."
# Clean block template using the specific variables set above
cat <<EOF > "${OUTPUT_SUB_PATH}/release_notes.md"
## AWS CLI V2 Index: ${AWS_CLI_VERSION}

This project provides independent verification and direct metadata for AWS CLI v2 binaries.

* Official AWS source tag: ${AWS_CLI_VERSION}: [${AWS_TAG_URL}](${AWS_TAG_URL})
* AMD64/x86_64 URL:  [${AMD_URL}](${AMD_URL})
* ARM64/aarch64 URL: [${ARM_URL}](${ARM_URL})
* SHA512 checksum file for AMD64/x86_64  [${AMD_SHA512:0:30}...](https://github.com/kube-kaptain/aws-cli-v2-index/releases/download/${AWS_CLI_VERSION}/amd.sha512)
* SHA512 checksum file for ARM64/aarch64 [${ARM_SHA512:0:30}...](https://github.com/kube-kaptain/aws-cli-v2-index/releases/download/${AWS_CLI_VERSION}/arm.sha512)

Use the following patterns in your Dockerfile builds:

\`\`\`
# AMD64/x86_64:
ENV AWS_CLI_VERSION=${AWS_CLI_VERSION}
ENV AWS_CLI_URL=https://awscli.amazonaws.com/awscli-exe-linux-x86_64-\${AWS_CLI_VERSION}.zip\`

# ARM64/aarch64:
ENV AWS_CLI_VERSION=${AWS_CLI_VERSION}
ENV AWS_CLI_URL=https://awscli.amazonaws.com/awscli-exe-linux-aarch64-\${AWS_CLI_VERSION}.zip\`
\`\`\`

Raw SHA512 checksums:

* AMD64/x86_64  ${AMD_SHA512}
* ARM64/aarch6: ${ARM_SHA512}

Independently validate by grabbing a checksum from this release:

For AMD64/x86_64:

\`\`\`bash
# 1. Download the binary and the trusted checksum
curl -sL "\${AWS_CLI_URL}" -o awscliv2.zip
curl -sL "https://github.com/kube-kaptain/aws-cli-v2-index/releases/download/\${AWS_CLI_VERSION}/amd.sha512" -o trusted.sha512

# 2. Compare them
echo "\$(cat trusted.sha512)  awscliv2.zip" | sha512sum --check
\`\`\`

For ARM64/aarch64:

\`\`\`bash
# 1. Download the binary and the trusted checksum
curl -sL "\${AWS_CLI_URL}" -o awscliv2.zip
curl -sL "https://github.com/kube-kaptain/aws-cli-v2-index/releases/download/\${AWS_CLI_VERSION}/arm.sha512" -o trusted.sha512

# 2. Compare them
echo "\$(cat trusted.sha512)  awscliv2.zip" | sha512sum --check
\`\`\`

Please note that the ARM binary version is not verified, but it should be the same as the amd one.

EOF

echo "Complete. All files generated in ${OUTPUT_SUB_PATH}"
