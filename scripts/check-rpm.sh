#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
rpm_path=${1:-}

if [[ -z "$rpm_path" || $# -ne 1 ]]; then
    printf 'usage: %s PATH-TO-GPARTED-RPM\n' "$0" >&2
    exit 2
fi

if [[ ! -f "$rpm_path" ]]; then
    printf 'error: RPM not found: %s\n' "$rpm_path" >&2
    exit 1
fi

rpm_path=$(realpath "$rpm_path")

for command_name in cpio ldd readelf realpath rpm rpm2cpio strings; do
    if ! command -v "$command_name" >/dev/null; then
        printf 'error: required command not found: %s\n' "$command_name" >&2
        exit 1
    fi
done

mkdir -p "$repo_root/.build"
stage_dir=$(mktemp -d "$repo_root/.build/rpm-audit.XXXXXX")
trap 'rm -rf "$stage_dir"' EXIT

printf 'Package integrity\n'
rpm -K "$rpm_path"

package_name=$(rpm -qp --qf '%{NAME}\n' "$rpm_path")
if [[ "$package_name" != gparted ]]; then
    printf 'error: expected the main gparted RPM, got: %s\n' \
        "$package_name" >&2
    exit 1
fi

file_list=$(rpm -qpl "$rpm_path")
for required_path in \
    /usr/bin/gparted \
    /usr/libexec/gpartedbin \
    /usr/share/applications/gparted.desktop \
    /usr/share/metainfo/gparted.appdata.xml \
    /usr/share/polkit-1/actions/org.gnome.gparted.policy; do
    if ! grep -Fxq "$required_path" <<<"$file_list"; then
        printf 'error: required packaged path missing: %s\n' \
            "$required_path" >&2
        exit 1
    fi
done

if grep -q '^/usr/local/' <<<"$file_list"; then
    printf 'error: package unexpectedly writes below /usr/local\n' >&2
    exit 1
fi
printf 'ok       package file layout\n'

(
    cd "$stage_dir"
    rpm2cpio "$rpm_path" | cpio --quiet -idm
)

wrapper="$stage_dir/usr/bin/gparted"
backend="$stage_dir/usr/libexec/gpartedbin"

if [[ ! -x "$wrapper" || ! -x "$backend" ]]; then
    printf 'error: extracted launch files are not executable\n' >&2
    exit 1
fi
printf 'ok       extracted executable modes\n'

if ldd "$backend" | grep -q 'not found'; then
    ldd "$backend" | grep 'not found' >&2
    exit 1
fi
printf 'ok       all shared libraries resolve on this build host\n'

if readelf -d "$backend" | grep -Eq '\((RPATH|RUNPATH)\)'; then
    printf 'error: packaged backend contains RPATH or RUNPATH\n' >&2
    readelf -d "$backend" | grep -E '\((RPATH|RUNPATH)\)' >&2
    exit 1
fi
printf 'ok       no embedded RPATH or RUNPATH\n'

if strings "$backend" | grep -Fq "$repo_root"; then
    printf 'error: packaged backend embeds the local repository path\n' >&2
    exit 1
fi
printf 'ok       no local repository path embedded\n'

printf '\nRPM audit passed: %s\n' "$rpm_path"
