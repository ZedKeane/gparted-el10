#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
topdir=${RPM_TOPDIR:-"$repo_root/.build/rpmbuild"}
log_file=${BUILD_LOG:-"$repo_root/.build/build.log"}

for command_name in rpmbuild tee; do
    if ! command -v "$command_name" >/dev/null; then
        printf 'error: required command not found: %s\n' "$command_name" >&2
        exit 1
    fi
done

mkdir -p "$topdir"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "$(dirname "$log_file")"

run_build() {
    "$repo_root/scripts/fetch-source.sh"

    rpmbuild -ba \
        --define "_topdir $topdir" \
        "$repo_root/gparted.spec"

    printf '\nBuilt packages:\n'
    find "$topdir/RPMS" "$topdir/SRPMS" -type f \
        \( -name '*.rpm' -o -name '*.src.rpm' \) -print | sort
}

run_build 2>&1 | tee "$log_file"
if grep -Fq 'configure: WARNING: unrecognized options:' "$log_file"; then
    printf 'error: upstream configure options were not recognized\n' >&2
    exit 1
fi
printf 'Build log: %s\n' "$log_file"
