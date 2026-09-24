# GParted 1.8.1 file-system capability matrix

[English](filesystem-matrix.md) | [简体中文](filesystem-matrix.zh-CN.md)

This matrix audits every file system listed by the upstream GParted feature
table. It describes GParted capabilities, not a promise that every helper is
available from RHEL 10 and EPEL 10 repositories.

Legend:

- **Yes**: supported while unmounted.
- **Yes+online**: supported while unmounted and, where shown by GParted,
  while mounted.
- **Online only**: supported only while the containing layer is active.
- **Basic**: GParted can perform a raw block move or copy without
  understanding the file system.
- **No**: not implemented by GParted 1.8.1 and its supported helper tools.

| File system | Detect | Read | Create | Grow | Shrink | Move | Copy | Check | Label | UUID |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| APFS | Yes | No | No | No | No | Basic | Basic | No | No | No |
| bcachefs | Yes | Online only | Yes | Yes+online | No | Yes | Yes | Yes | No | No |
| BitLocker | Yes | No | No | No | No | Basic | Basic | No | No | No |
| Btrfs | Yes | Yes | Yes | Yes+online | Yes+online | Yes | Yes | Yes | Yes | Yes |
| exFAT | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| ext2 | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| ext3 | Yes | Yes | Yes | Yes+online | Yes | Yes | Yes | Yes | Yes | Yes |
| ext4 | Yes | Yes | Yes | Yes+online | Yes | Yes | Yes | Yes | Yes | Yes |
| F2FS | Yes | Yes | Yes | Yes | No | Yes | Yes | Yes | No | No |
| FAT16 | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| FAT32 | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| HFS | Yes | Yes | Yes | No | Yes | Yes | Yes | No | No | No |
| HFS+ | Yes | Yes | Yes | No | Yes | Yes | Yes | Yes | No | No |
| JFS | Yes | Yes | Yes | Yes+online | No | Yes | Yes | Yes | Yes | Yes |
| Linux software RAID | Yes | No | No | No | No | Basic | Basic | No | No | No |
| Linux suspend | Yes | No | No | No | No | Basic | Basic | No | No | No |
| Linux swap | Yes | Yes | Yes | Yes | Yes | Yes | Yes | No | Yes | Yes |
| LUKS | Yes | Yes | No | Yes+online | Online only | Yes | Yes | No | No | No |
| LVM2 PV | Yes | Yes | Yes | Yes+online | Yes+online | Yes | No | Yes | No | No |
| Minix | Yes | No | Yes | No | No | Yes | Yes | Yes | No | No |
| NILFS2 | Yes | Yes | Yes | Yes+online | Yes+online | Yes | Yes | No | Yes | Yes |
| NTFS | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| ReFS | Yes | No | No | No | No | Basic | Basic | No | No | No |
| Reiser4 | Yes | Yes | Yes | No | No | Yes | Yes | Yes | No | No |
| ReiserFS | Yes | Yes | Yes | Yes+online | Yes | Yes | Yes | Yes | Yes | Yes |
| UDF | Yes | Yes | Yes | No | No | Yes | Yes | No | Yes | Yes |
| UFS | Yes | No | No | No | No | Basic | Basic | No | No | No |
| XFS | Yes | Yes | Yes | Yes+online | No | Yes | Yes | Yes | Yes | Yes |
| ZFS | Yes | No | No | No | No | Basic | Basic | No | No | No |

## RHEL 10 coverage

The project installs or recommends the helper stacks that are available from
RHEL 10 and EPEL 10:

| Coverage | File systems or layers | RHEL 10 packages and limitations |
| --- | --- | --- |
| Full common helper coverage | ext2/3/4, FAT16/32, exFAT, Minix, NTFS, XFS, Linux swap | e2fsprogs, dosfstools, mtools, exfatprogs, util-linux, ntfsprogs, ntfs-3g, xfsprogs, xfsdump |
| Storage-layer coverage | LUKS, LVM2 PV, Linux software RAID | cryptsetup, lvm2, mdadm |
| User-space only on RHEL | Btrfs | btrfs-progs is available, but the RHEL kernel has no Btrfs driver; mounted grow and shrink are unavailable |
| Basic move/copy only | APFS, BitLocker, Linux suspend, ReFS, UFS, ZFS | No helper is required for a same-size raw block move or copy; the source must be unmounted or closed |
| Helpers absent from standard RHEL 10/EPEL 10 repositories | bcachefs, F2FS, HFS/HFS+, JFS, NILFS2, Reiser4/ReiserFS, UDF | Do not mix Fedora RPMs or build private core stacks merely to fill these optional cells |

## Important interpretation

Moving and resizing are different operations. GParted can move an unmounted
exFAT partition without changing its size, but neither GParted nor
exfatprogs provides in-place exFAT grow or shrink. XFS can grow but cannot
shrink. Basic raw moves and copies preserve the original file-system size and
must not be presented as file-system-aware modification.

## Additional source-recognized types

GParted 1.8.1 source also recognizes ATA RAID members, GRUB2 `core.img`, and
ISO9660. They are not rows in the upstream public feature table, have no
dedicated file-system implementation, and only receive the same basic raw
move/copy action set. `unknown` and `other` are internal fallbacks with that
same basic action set; `cleared` and `unformatted` are creation choices rather
than existing file systems. They are documented here so that the 29-row
public matrix is not mistaken for the complete internal type enumeration.

The authoritative run-time result is **View → File System Support → Rescan For
Supported Actions** in the installed GParted. Run
scripts/verify-runtime.sh --strict to audit the recommended RHEL 10 helper set.

Sources:

- [GParted upstream feature table](https://gparted.org/features.php)
- GParted 1.8.1 src/SupportedFileSystems.cc and individual file-system
  implementation classes from the verified release archive
