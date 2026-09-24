# gparted-rhel10

[English](README.md) | [简体中文](README.zh-CN.md)

这是面向 Red Hat Enterprise Linux 10（RHEL 10）及兼容发行版的 GParted
可重复、可审计 RPM 打包项目，不是 GParted 的源码分叉。

目前 Fedora 为 Fedora、EPEL 8 和 EPEL 9 提供 GParted，但没有 EPEL 10
构建。GParted 所需的 GTKmm 3 兼容开发包现已进入 EPEL 10，因此本项目
可以生成原生 RPM，无需替换 RHEL 核心库，也无需在 `/usr/local` 维护一套
私有桌面依赖。

## 项目内容

- 基于 Fedora 官方打包的 RHEL 10 RPM spec。
- 校验上游源码的 SHA-512 和 OpenPGP 签名。
- 防止 Btrfs、ext2/3/4、FAT、exFAT、Linux swap、NTFS 和 XFS
  测试因缺少辅助工具而跳过却仍报告成功。
- 使用无界面 Wayland 合成器运行 GTK 测试，不依赖 RHEL 10 缺少的 Xvfb。
- 通过弱依赖安装常见文件系统工具。
- 提供安装后的运行时能力检查。
- 提供覆盖上游全部 29 种文件系统，以及创建、扩大、缩小、移动、复制、
  检查、标签和 UUID 操作的双语能力矩阵。

## 构建

先启用当前发行版对应的 CodeReady Builder/CRB 与 EPEL 10，然后运行：

```bash
sudo dnf install -y dnf-plugins-core rpm-build gnupg2 curl
sudo dnf builddep -y ./gparted.spec
./scripts/build-rpm.sh
```

RPM 会生成在 `.build/rpmbuild/RPMS`，SRPM 会生成在
`.build/rpmbuild/SRPMS`，完整控制台日志保存在 `.build/build.log`。

安装并检查：

```bash
./scripts/check-rpm.sh .build/rpmbuild/RPMS/*/gparted-[0-9]*.rpm
sudo dnf install .build/rpmbuild/RPMS/*/gparted-[0-9]*.rpm
./scripts/verify-runtime.sh
```

完整审查结果见[中文文件系统能力矩阵](docs/filesystem-matrix.zh-CN.md)。

在 RHEL 10 上，移动 NTFS 分区需要 `ntfsprogs` 提供的 `ntfsresize`；仅安装
`ntfs-3g` 不够。本项目会推荐安装两者，并在构建时实际运行 NTFS 辅助工具
测试。

exFAT 依赖 `exfatprogs`。GParted 1.8.1 可以创建、移动、复制、检查、
修改标签和 UUID，但上游没有实现 exFAT 原地扩大或缩小。保持原大小移动
分区不等于调整文件系统大小。

## RHEL 的 Btrfs 限制

RHEL 10 不提供 Btrfs 内核驱动。安装 `btrfs-progs` 后，GParted 可以读取、
检查、复制和离线移动未挂载的 Btrfs 分区；但需要挂载文件系统的 Btrfs
扩大和缩小仍不可用。需要调整 Btrfs 大小时，请使用 Fedora Live 或
GParted Live。

更多说明见 [docs/filesystem-support.md](docs/filesystem-support.md)。

## 简体中文兼容

上游源码包含完整的简体中文消息目录。如果中文桌面仍显示英文，应先检查
`LC_ALL`：它的优先级高于 `LANG` 和 `LC_MESSAGES`。可选脚本
`scripts/run-gparted-zh.sh` 会清除该覆盖，并使用 `zh_CN.UTF-8` 启动系统
安装的 `/usr/bin/gparted`。RPM 不会强制改变系统语言策略。

## 安全说明

本项目的脚本只负责下载、校验、构建和检查软件，不会执行任何磁盘分区
操作。实际修改分区前必须备份重要数据；移动操作系统分区时建议从 Live
环境启动。

本地构建和 GitHub Actions 产物默认没有 RPM 签名。公开发布可安装软件前，
应配置 RPM 签名密钥，或使用能为软件包及仓库元数据签名的 COPR 等构建服务。
