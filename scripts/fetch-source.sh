#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
spec_file="$repo_root/gparted.spec"
sources_file="$repo_root/sources"
topdir=${RPM_TOPDIR:-"$repo_root/.build/rpmbuild"}

for command_name in curl gpg rpmspec sha512sum; do
    if ! command -v "$command_name" >/dev/null; then
        printf 'error: required command not found: %s\n' "$command_name" >&2
        exit 1
    fi
done

version=$(rpmspec -q --qf '%{version}\n' "$spec_file" | head -n 1)
archive="gparted-${version}.tar.gz"
signature="${archive}.sig"
source_url="https://downloads.sourceforge.net/gparted/${archive}"
signature_url="${source_url}.sig"
source_dir="$topdir/SOURCES"

mkdir -p "$source_dir"

download() {
    local url=$1
    local destination=$2

    if [[ ! -s "$destination" ]]; then
        curl --fail --location --retry 5 --retry-all-errors \
            --output "$destination.part" "$url"
        mv "$destination.part" "$destination"
    fi
}

download "$source_url" "$source_dir/$archive"
download "$signature_url" "$source_dir/$signature"

expected_sha512=$(awk -v archive="$archive" \
    '$1 == "SHA512" && $2 == "(" archive ")" { print $4 }' \
    "$sources_file")

if [[ -z "$expected_sha512" ]]; then
    printf 'error: no SHA512 entry for %s in %s\n' \
        "$archive" "$sources_file" >&2
    exit 1
fi

printf '%s  %s\n' "$expected_sha512" "$source_dir/$archive" \
    | sha512sum --check --status
printf 'SHA512 verified: %s\n' "$archive"

keyring=$(mktemp -d)
trap 'find "$keyring" -depth -delete' EXIT
chmod 700 "$keyring"
gpg --batch --quiet --homedir "$keyring" \
    --import "$repo_root/keys/curtis-gedak.asc"

status_output=$(gpg --batch --homedir "$keyring" --status-fd 1 \
    --verify "$source_dir/$signature" "$source_dir/$archive" 2>/dev/null)
fingerprint=$(awk '$1 == "[GNUPG:]" && $2 == "VALIDSIG" { print $3 }' \
    <<<"$status_output")
expected_fingerprint=BB09FFB87563FA2E1A22146817A6D3FF338C9570

if [[ "$fingerprint" != "$expected_fingerprint" ]]; then
    printf 'error: unexpected signing key fingerprint: %s\n' \
        "${fingerprint:-none}" >&2
    exit 1
fi

printf 'OpenPGP signature verified: %s\n' "$expected_fingerprint"
