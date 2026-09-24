#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
matrix="$repo_root/docs/filesystem-matrix.md"
matrix_zh="$repo_root/docs/filesystem-matrix.zh-CN.md"

for required_file in \
    "$repo_root/README.md" \
    "$repo_root/README.zh-CN.md" \
    "$matrix" \
    "$matrix_zh" \
    "$repo_root/docs/filesystem-support.md" \
    "$repo_root/docs/filesystem-support.zh-CN.md"; do
    if [[ ! -s "$required_file" ]]; then
        printf 'error: required documentation missing: %s\n' "$required_file" >&2
        exit 1
    fi
done

expected_filesystems=(
    APFS
    bcachefs
    BitLocker
    Btrfs
    exFAT
    ext2
    ext3
    ext4
    F2FS
    FAT16
    FAT32
    HFS
    HFS+
    JFS
    "Linux software RAID"
    "Linux suspend"
    "Linux swap"
    LUKS
    "LVM2 PV"
    Minix
    NILFS2
    NTFS
    ReFS
    Reiser4
    ReiserFS
    UDF
    UFS
    XFS
    ZFS
)

for fs_name in "${expected_filesystems[@]}"; do
    if ! grep -Fq "| $fs_name |" "$matrix"; then
        printf 'error: upstream file system missing from matrix: %s\n' \
            "$fs_name" >&2
        exit 1
    fi
done

english_rows=$(grep -Ec '^\| .+ \| (Yes|No) \|' "$matrix")
chinese_rows=$(grep -Ec '^\| .+ \| (支持|不支持) \|' "$matrix_zh")
if [[ "$english_rows" -ne 29 || "$chinese_rows" -ne 29 ]]; then
    printf 'error: expected 29 capability rows, got English=%s Chinese=%s\n' \
        "$english_rows" "$chinese_rows" >&2
    exit 1
fi

# Verify that the two matrices have the same row order and that every one of
# the ten capability cells has an exact, semantically matching translation.
awk -F '|' '
    function trim(value) {
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        return value
    }
    BEGIN {
        translated["支持"] = "Yes"
        translated["不支持"] = "No"
        translated["支持+在线"] = "Yes+online"
        translated["仅在线"] = "Online only"
        translated["基础"] = "Basic"
        translated_name["Linux software RAID"] = "Linux 软件 RAID"
        translated_name["Linux suspend"] = "Linux 休眠"
        allowed["Yes"] = allowed["No"] = 1
        allowed["Yes+online"] = allowed["Online only"] = 1
        allowed["Basic"] = 1
    }
    FNR == NR && /^\| .+ \| (Yes|No) \|/ {
        if (NF != 13) {
            print "error: malformed English capability row: " $0 > "/dev/stderr"
            failed = 1
            next
        }
        english_count++
        names[english_count] = trim($2)
        for (column = 3; column <= 12; column++) {
            value = trim($column)
            if (!(value in allowed)) {
                print "error: invalid English capability: " value > "/dev/stderr"
                failed = 1
            }
            capabilities[english_count, column] = value
        }
        next
    }
    FNR != NR && /^\| .+ \| (支持|不支持) \|/ {
        if (NF != 13) {
            print "error: malformed Chinese capability row: " $0 > "/dev/stderr"
            failed = 1
            next
        }
        chinese_count++
        expected_name = names[chinese_count]
        if (expected_name in translated_name)
            expected_name = translated_name[expected_name]
        if (trim($2) != expected_name) {
            print "error: matrix row mismatch: " trim($2) > "/dev/stderr"
            failed = 1
        }
        for (column = 3; column <= 12; column++) {
            value = trim($column)
            if (!(value in translated) ||
                translated[value] != capabilities[chinese_count, column]) {
                print "error: bilingual capability mismatch in " trim($2) > "/dev/stderr"
                failed = 1
            }
        }
    }
    END {
        if (english_count != 29 || chinese_count != 29)
            failed = 1
        exit failed
    }
' "$matrix" "$matrix_zh"

grep -Fqx '| exFAT | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |' \
    "$matrix"
grep -Fqx '| exFAT | 支持 | 支持 | 支持 | 不支持 | 不支持 | 支持 | 支持 | 支持 | 支持 | 支持 |' \
    "$matrix_zh"

grep -Fq '[简体中文](README.zh-CN.md)' "$repo_root/README.md"
grep -Fq '[English](README.md)' "$repo_root/README.zh-CN.md"
grep -Fq 'filesystem-matrix.md' "$repo_root/README.md"
grep -Fq 'filesystem-matrix.zh-CN.md' "$repo_root/README.zh-CN.md"
for source_only_type in 'ATA RAID' "GRUB2 \`core.img\`" ISO9660; do
    grep -Fq "$source_only_type" "$matrix"
    grep -Fq "$source_only_type" "$matrix_zh"
done

printf 'Documentation audit passed: 29 upstream file systems in both matrices.\n'
