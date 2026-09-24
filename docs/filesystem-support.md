# File-system support on RHEL 10

[English](filesystem-support.md) | [简体中文](filesystem-support.zh-CN.md)

GParted compiles file-system back ends into the application, but discovers
most native helper tools each time it starts.  A successful build therefore
does not prove that every operation is available at run time.

The complete operation-by-operation audit of all 29 upstream entries is in
[filesystem-matrix.md](filesystem-matrix.md).  The table below focuses on the
common helper stacks available from RHEL 10 and EPEL 10 repositories.

Common helpers include:

| File system or layer | Important packages | Typical capabilities |
| --- | --- | --- |
| Btrfs | `btrfs-progs` | Read, check, copy, move, create |
| ext2/3/4 | `e2fsprogs` | Check, grow, shrink, move |
| XFS | `xfsprogs`, `xfsdump` | Check, grow, move, copy; XFS cannot shrink directly |
| NTFS | `ntfsprogs`, `ntfs-3g` | Check, grow, shrink, move, copy, create |
| FAT | `dosfstools`, `mtools` | Create, check, labels, UUIDs |
| exFAT | `exfatprogs` | Create, check, labels, UUIDs, same-size move and copy; no grow or shrink |
| Minix | `util-linux` | Create, check, same-size move and copy |
| Linux swap | `util-linux` | Create, resize, move, copy, label, UUID |
| LUKS | `cryptsetup` | Open, close, and supported resize operations |
| LVM2 PV | `lvm2` | Activate, deactivate, check, and resize |

Run `scripts/verify-runtime.sh` after installation.  In GParted, use
**View → File System Support** and select **Rescan For Supported Actions**
after adding or removing helper packages.

## exFAT on RHEL 10

GParted uses `dump.exfat`, `mkfs.exfat`, `fsck.exfat`, and `tune.exfat` from
`exfatprogs`.  Together they enable usage reporting, creation, consistency
checking, labels, and UUIDs.  GParted itself provides same-size block move and
copy for an unmounted exFAT partition.

There is no supported exFAT resize helper.  Consequently the resize/move
dialog can change free space before and after an unmounted exFAT partition,
but its file-system size remains fixed.  Do not present backup, reformat, and
restore as an in-place resize operation.

## NTFS on RHEL 10

RHEL 10 and EPEL 10 split the NTFS stack into multiple packages.  In particular,
`ntfsresize`, which GParted uses to validate and enable NTFS resize and move,
is provided by `ntfsprogs`, not by the `ntfs-3g` package.  This repository
therefore recommends both packages and runs NTFS helper tests during the RPM
build.

The NTFS partition must be unmounted before it can be moved.  Windows should
be fully shut down first; hibernation and Fast Startup can leave the file
system unsafe to modify.  After moving or resizing a Windows NTFS system
partition, boot Windows twice so it can complete consistency checks.

## Btrfs on RHEL

Red Hat removed Btrfs kernel support beginning with RHEL 8.  Installing
`btrfs-progs` restores GParted's user-space Btrfs inspection, check, copy, and
offline block-move capabilities, but it does not add a Btrfs kernel driver.
Operations that require mounting Btrfs, including GParted's Btrfs grow and
shrink implementation, remain unavailable on an unmodified RHEL 10 kernel.

Use Fedora Live or GParted Live when Btrfs resizing is required.

## Moving partitions safely

- The partition must be unmounted and inactive.
- A closed LUKS mapping can be moved; an open mapping cannot.
- LVM logical volumes and volume groups must be inactive before moving a PV.
- Unallocated space must be immediately adjacent to the partition.
- Moving an operating-system partition can break its boot loader.
- Back up important data and use reliable power before applying operations.

This repository builds software only.  Its scripts never queue or apply a
partition-table change.
