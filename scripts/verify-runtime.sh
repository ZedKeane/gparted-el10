#!/usr/bin/env bash
set -euo pipefail

strict=false
require_zh=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --strict)
            strict=true
            ;;
        --require-zh)
            require_zh=true
            ;;
        *)
            printf 'usage: %s [--strict] [--require-zh]\n' "$0" >&2
            exit 2
            ;;
    esac
    shift
done

errors=0
warnings=0

check_required() {
    local command_name=$1
    if command -v "$command_name" >/dev/null; then
        printf 'ok       %-18s %s\n' "$command_name" "$(command -v "$command_name")"
    else
        printf 'missing  %-18s required\n' "$command_name"
        errors=$((errors + 1))
    fi
}

check_helper() {
    local command_name=$1
    local capability=$2
    if command -v "$command_name" >/dev/null; then
        printf 'ok       %-18s %s\n' "$command_name" "$capability"
    else
        printf 'optional %-18s %s unavailable\n' "$command_name" "$capability"
        warnings=$((warnings + 1))
    fi
}

check_optional_helper() {
    local command_name=$1
    local capability=$2
    if command -v "$command_name" >/dev/null; then
        printf 'ok       %-18s %s\n' "$command_name" "$capability"
    else
        printf 'absent   %-18s %s (optional on RHEL 10)\n' \
            "$command_name" "$capability"
    fi
}

printf 'GParted launch requirements\n'
check_required gparted
check_required pkexec
check_required xhost

gparted_bin=$(command -v gparted || true)
if [[ -n "$gparted_bin" ]]; then
    backend=/usr/libexec/gpartedbin
    if [[ -x "$backend" ]]; then
        if ldd "$backend" | grep -q 'not found'; then
            ldd "$backend" | grep 'not found'
            errors=$((errors + 1))
        else
            printf 'ok       %-18s all shared libraries resolved\n' gpartedbin
        fi
    else
        printf 'missing  %-18s %s\n' gpartedbin "$backend"
        errors=$((errors + 1))
    fi
fi

printf '\nRecommended RHEL 10 file-system helpers\n'
check_helper btrfs 'Btrfs read/check/label'
check_helper mkfs.btrfs 'Btrfs create'
check_helper btrfstune 'Btrfs UUID'

check_helper mke2fs 'ext2/3/4 create'
check_helper mkfs.ext2 'ext2 create as detected by GParted'
check_helper mkfs.ext3 'ext3 create as detected by GParted'
check_helper mkfs.ext4 'ext4 create as detected by GParted'
check_helper dumpe2fs 'ext2/3/4 usage'
check_helper e2fsck 'ext2/3/4 check'
check_helper resize2fs 'ext2/3/4 grow/shrink'
check_helper e2label 'ext2/3/4 label'
check_helper tune2fs 'ext2/3/4 UUID'
check_helper e2image 'ext2/3/4 optimized move/copy'

check_helper mkfs.fat 'FAT16/32 create'
check_helper fsck.fat 'FAT16/32 check'
check_helper fatlabel 'FAT16/32 read label'
check_helper mdir 'FAT16/32 usage and UUID'
check_helper minfo 'FAT16/32 usage'
check_helper mlabel 'FAT16/32 write label and UUID'

check_helper dump.exfat 'exFAT usage'
check_helper mkfs.exfat 'exFAT create'
check_helper fsck.exfat 'exFAT check'
check_helper tune.exfat 'exFAT label and UUID'
exfat_tune_help=$(LC_ALL=C tune.exfat 2>&1 || true)
if grep -Fq 'Set volume serial' <<<"$exfat_tune_help"; then
    printf 'ok       %-18s version supports create, label and UUID\n' \
        exfatprogs
else
    printf 'missing  %-18s installed tune.exfat lacks volume serial support\n' \
        exfatprogs
    errors=$((errors + 1))
fi

check_helper mkfs.minix 'Minix create'
check_helper fsck.minix 'Minix check'

check_helper ntfsinfo 'NTFS usage'
check_helper ntfsresize 'NTFS check/grow/shrink/move'
check_helper ntfsclone 'NTFS copy'
check_helper mkntfs 'NTFS create'
check_helper ntfslabel 'NTFS label and UUID'

check_helper xfs_db 'XFS usage, label and UUID'
check_helper xfs_admin 'XFS label and UUID'
check_helper xfs_io 'XFS online label'
check_helper mkfs.xfs 'XFS create'
check_helper xfs_repair 'XFS check'
check_helper xfs_growfs 'XFS grow'
check_helper xfsdump 'XFS optimized copy'
check_helper xfsrestore 'XFS optimized copy'

check_helper mkswap 'Linux swap create/resize/move/copy'
check_helper swaplabel 'Linux swap label and UUID'
check_helper cryptsetup 'LUKS operations'
check_helper lvm 'LVM2 physical volumes'
check_helper mdadm 'Linux software RAID detection'
check_helper blkid 'file-system detection'
check_helper mount 'mounted grow operations'
check_helper umount 'offline operations'

printf '\nAdditional upstream helpers not provided by standard RHEL 10/EPEL 10 repositories\n'
check_optional_helper bcachefs 'bcachefs create/read/grow/check'
check_optional_helper dump.f2fs 'F2FS usage'
check_optional_helper mkfs.f2fs 'F2FS create'
check_optional_helper fsck.f2fs 'F2FS check'
check_optional_helper resize.f2fs 'F2FS grow'
check_optional_helper hformat 'HFS create'
check_optional_helper hfsck 'HFS check'
check_optional_helper mkfs.hfsplus 'HFS+ create'
check_optional_helper fsck.hfsplus 'HFS+ check'
check_optional_helper jfs_debugfs 'JFS usage'
check_optional_helper mkfs.jfs 'JFS create'
check_optional_helper jfs_fsck 'JFS check'
check_optional_helper jfs_tune 'JFS label and UUID'
check_optional_helper nilfs-tune 'NILFS2 usage, label and UUID'
check_optional_helper mkfs.nilfs2 'NILFS2 create'
check_optional_helper nilfs-resize 'NILFS2 resize'
check_optional_helper debugfs.reiser4 'Reiser4 usage and label'
check_optional_helper mkfs.reiser4 'Reiser4 create'
check_optional_helper fsck.reiser4 'Reiser4 check'
check_optional_helper debugreiserfs 'ReiserFS usage and label'
check_optional_helper mkreiserfs 'ReiserFS create'
check_optional_helper reiserfsck 'ReiserFS check'
check_optional_helper resize_reiserfs 'ReiserFS resize'
check_optional_helper reiserfstune 'ReiserFS label and UUID'
check_optional_helper mkudffs 'UDF create'
check_optional_helper udfinfo 'UDF usage and UUID'
check_optional_helper udflabel 'UDF label and UUID'

printf '\nChinese localization\n'
zh_catalog=/usr/share/locale/zh_CN/LC_MESSAGES/gparted.mo
if [[ -r "$zh_catalog" ]]; then
    printf 'ok       %-18s Simplified Chinese message catalog\n' zh_CN
else
    printf 'missing  %-18s %s\n' zh_CN "$zh_catalog"
    errors=$((errors + 1))
fi
translated_support=$(env -u LC_ALL \
    LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_MESSAGES=zh_CN.UTF-8 \
    gettext -d gparted 'File System Support')
if [[ "$translated_support" == '文件系统支持' ]]; then
    printf 'ok       %-18s translated message lookup\n' gettext
else
    printf 'missing  %-18s expected Chinese message, got: %s\n' \
        gettext "$translated_support"
    errors=$((errors + 1))
fi
desktop_file=/usr/share/applications/gparted.desktop
if [[ -r "$desktop_file" ]] \
    && grep -Fqx 'GenericName[zh_CN]=分区编辑器' "$desktop_file" \
    && grep -Fqx 'Comment[zh_CN]=创建、重新组织或删除分区' "$desktop_file"; then
    printf 'ok       %-18s Chinese desktop metadata\n' desktop-entry
else
    printf 'missing  %-18s Chinese desktop metadata\n' desktop-entry
    errors=$((errors + 1))
fi
policy_file=/usr/share/polkit-1/actions/org.gnome.gparted.policy
if [[ -r "$policy_file" ]] \
    && grep -Fq '<description xml:lang="zh_CN">' "$policy_file" \
    && grep -Fq '<message xml:lang="zh_CN">' "$policy_file"; then
    printf 'ok       %-18s Chinese authorization prompt\n' polkit
else
    printf 'missing  %-18s Chinese authorization prompt\n' polkit
    errors=$((errors + 1))
fi
if locale -a | grep -Eiq '^zh_CN[.]utf-?8$'; then
    printf 'ok       %-18s zh_CN.UTF-8 locale available\n' locale
elif [[ "$require_zh" == true ]]; then
    printf 'missing  %-18s zh_CN.UTF-8 locale unavailable\n' locale
    errors=$((errors + 1))
else
    printf 'optional %-18s install glibc-langpack-zh for Chinese UI\n' locale
fi
if [[ ${LANG-} == zh_CN* && ${LC_ALL-} == C* ]]; then
    printf 'warning  %-18s LC_ALL=%s overrides LANG=%s and forces English\n' \
        locale-precedence "$LC_ALL" "$LANG"
    if [[ "$require_zh" == true ]]; then
        errors=$((errors + 1))
    else
        warnings=$((warnings + 1))
    fi
fi

printf '\nSummary: %d error(s), %d optional helper warning(s)\n' \
    "$errors" "$warnings"

if (( errors > 0 )); then
    exit 1
fi
if [[ "$strict" == true && $warnings -gt 0 ]]; then
    exit 1
fi
