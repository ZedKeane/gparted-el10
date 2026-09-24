# RHEL 10 文件系统支持

[English](filesystem-support.md) | [简体中文](filesystem-support.zh-CN.md)

GParted 会把文件系统后端编入程序，但每次启动时仍需检测大部分原生辅助工具。
因此，编译成功不代表运行时所有操作都可用。

全部 29 种上游文件系统逐项审查见[文件系统能力矩阵](filesystem-matrix.zh-CN.md)。
下表仅列出 RHEL 10 和 EPEL 10 仓库能够提供的常用辅助工具。

| 文件系统或存储层 | 重要软件包 | 典型能力 |
| --- | --- | --- |
| Btrfs | `btrfs-progs` | 读取、检查、复制、移动、创建 |
| ext2/3/4 | `e2fsprogs` | 检查、扩大、缩小、移动 |
| XFS | `xfsprogs`、`xfsdump` | 检查、扩大、移动、复制；XFS 不能直接缩小 |
| NTFS | `ntfsprogs`、`ntfs-3g` | 检查、扩大、缩小、移动、复制、创建 |
| FAT | `dosfstools`、`mtools` | 创建、检查、标签、UUID |
| exFAT | `exfatprogs` | 创建、检查、标签、UUID、保持原大小移动和复制；不能扩大或缩小 |
| Minix | `util-linux` | 创建、检查、保持原大小移动和复制 |
| Linux swap | `util-linux` | 创建、调整大小、移动、复制、标签、UUID |
| LUKS | `cryptsetup` | 打开、关闭及支持的调整大小操作 |
| LVM2 PV | `lvm2` | 激活、停用、检查和调整大小 |

安装后运行 `scripts/verify-runtime.sh`。新增或移除辅助工具后，在 GParted 中
打开“查看 → 文件系统支持”，选择“重新扫描支持的操作”。

## RHEL 10 上的 exFAT

GParted 使用 `exfatprogs` 提供的 `dump.exfat`、`mkfs.exfat`、`fsck.exfat`
和 `tune.exfat` 检测用量、创建、检查以及修改标签和 UUID。对于未挂载的
exFAT 分区，GParted 还可按原大小逐块移动和复制。

没有受支持的 exFAT 调整大小工具。因此“调整大小/移动”对话框虽然能改变
分区前后的空闲空间，但文件系统大小保持不变。备份、重新格式化、恢复数据
也不应称作原地调整大小。

## RHEL 10 上的 NTFS

RHEL 10 与 EPEL 10 将 NTFS 工具拆分到多个软件包。GParted 用于校验并启用
NTFS 调整大小和移动功能的 `ntfsresize` 属于 `ntfsprogs`，而不是 `ntfs-3g`。
因此本项目推荐安装两者，并在 RPM 构建时运行 NTFS 辅助工具测试。

移动前必须卸载 NTFS 分区。Windows 应完全关机；休眠和“快速启动”可能使
文件系统处于不安全状态。移动或调整 Windows 系统分区后，让 Windows
启动两次以完成一致性检查。

## RHEL 上的 Btrfs

Red Hat 从 RHEL 8 开始移除 Btrfs 内核支持。安装 `btrfs-progs` 可恢复
GParted 用户空间的读取、检查、复制和离线逐块移动功能，但不会添加内核
驱动。需要挂载 Btrfs 的操作，包括 GParted 的扩大和缩小实现，在未修改的
RHEL 10 内核上仍不可用。

需要调整 Btrfs 大小时，请使用 Fedora Live 或 GParted Live。

## 安全移动分区

- 分区必须已卸载且不处于活动状态。
- 关闭的 LUKS 映射可以移动；打开的映射不能移动。
- 移动 LVM 物理卷前，必须停用相关逻辑卷和卷组。
- 分区旁边必须紧邻未分配空间。
- 移动操作系统分区可能破坏引导加载程序。
- 执行前备份重要数据，并确保供电可靠。

本项目只构建软件；脚本不会排队或应用任何分区表变更。
