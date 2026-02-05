# AWS CLI V2 Index

This project provides an independent, versioned index of official AWS CLI V2
binaries. By offering out-of-band checksums (SHA512) and verified installation
metadata, it enables secure, immutable, and automated workflows for CI/CD
pipelines and Docker builds. If you were ever frustrated with Amazon's download
page only giving an unversioned link and no version index, this repo is for you.


## Project Rationale

While AWS provides a "latest" download link, relying on it in any robust build
with checksum verification makes for a fragile build that never runs when you need
it to, always failing on the checksum of the binary changing. Not to mention the
inherent risk of a corrupt or malicious binary entering your supply chain if you
don't do a reasonable job of verification. AWS suggests checking the signed
binaries using its GPG signing key; however this approach is clunky, and if you
get the GPG key and signature and binary from the same site, it's not robust.
Instead using a checksum from here and a binary from there gives you peace of
mind with a simple lightweight process. Key points:

* Ensures Immutability: Maps specific AWS CLI versions to their official Amazon CDN URLs so you can pin versions with confidence.
* Dual-Arch Verification: Every provided version is automatically extracted and executed on AMD64 (native) and ARM64 (via QEMU) to ensure binary integrity before metadata is published.
* Secondary Chain of Trust: Provides an independent source for checksums to prevent supply-chain attacks if the primary source is compromised.


## Download URL Patterns

You can reliably download specific versions using the following patterns:

* AMD64/x86\_64: `https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip`
* ARM64/aarch64: `https://awscli.amazonaws.com/awscli-exe-linux-aarch64-${AWS_CLI_VERSION}.zip`


## How to Use

To automate your builds with verification, reference the assets and instructions provided in our [GitHub Releases](https://github.com/kube-kaptain/aws-cli-v2-index/releases).


## Need a specific version?

Just raise a PR changing the version number in the [VERSION](VERSION) file in the repo root :-)

Old versions are fine and can be built out of order, but the latest version must
not have already been built. We want the latest at the top of the release page,
and since exact mode fails when a tag already exists, the latest must remain
unbuilt so it can be rebuilt and tagged last after the old version is done.

Valid versions can be found [here](https://github.com/aws/aws-cli/tags) - only 2.X.Y are accepted.
