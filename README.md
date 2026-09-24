# gparted-rhel10

[English](README.md) | [简体中文](README.zh-CN.md)

Audited, repeatable RPM packaging for GParted on Red Hat Enterprise Linux 10
(RHEL 10) and compatible distributions.

Fedora packages GParted for current Fedora releases and EPEL 8/9, but there is
currently no EPEL 10 build.  The GTKmm 3 compatibility stack and other build
requirements are available in EPEL 10, so this project packages GParted
without replacing RHEL core libraries or installing a private desktop stack
under `/usr/local`.

## What this repository provides

- A RHEL 10 RPM spec derived from Fedora's official GParted packaging.
- Pinned SHA-512 and OpenPGP verification of the upstream release archive.
- `%check` guards that catch silently skipped Btrfs, ext2/3/4, FAT, exFAT,
  Linux swap, NTFS, and XFS helper tests.
- Headless GTK tests using a native Wayland compositor instead of unavailable
  RHEL 10 Xvfb tooling.
- Weak dependencies for common file-system helper packages.
- A post-install run-time capability check.
- A bilingual matrix covering all 29 file systems in the upstream feature
  table and every create, grow, shrink, move, copy, check, label, and UUID
  capability.

This is packaging, not a fork of GParted.  Upstream source code is downloaded
from the GParted project and is not vendored here.

## Supported targets

- Red Hat Enterprise Linux 10
- CentOS Stream 10
- AlmaLinux 10 and Rocky Linux 10, when matching EPEL 10 packages are enabled

GitHub Actions builds in a CentOS Stream 10 container; this is not a substitute
for testing the resulting RPM on each supported distribution.

## Install a release

Download the x86_64 RPM and `SHA256SUMS` from the
[Releases page](https://github.com/ZedKeane/gparted-rhel10/releases), then run:

```bash
sha256sum -c --ignore-missing SHA256SUMS
sudo dnf install ./gparted-1.8.1-2.el10.x86_64.rpm
```

The RPM is unsigned. The checksum detects transfer errors but does not prove
the publisher's identity. These release assets are not a signed RPM repository.

## Build

Enable the distribution's CodeReady Builder/CRB repository and EPEL 10, then
install RPM build tooling and the spec's build dependencies:

```bash
sudo dnf install -y dnf-plugins-core rpm-build gnupg2 curl
sudo dnf builddep -y ./gparted.spec
./scripts/build-rpm.sh
```

Packages are written below `.build/rpmbuild/RPMS` and
`.build/rpmbuild/SRPMS`.  The complete console log is retained as
`.build/build.log`.

Install the generated binary RPM with DNF so weak dependencies are handled:

```bash
./scripts/check-rpm.sh .build/rpmbuild/RPMS/*/gparted-[0-9]*.rpm
sudo dnf install .build/rpmbuild/RPMS/*/gparted-[0-9]*.rpm
./scripts/verify-runtime.sh
```

To inspect GParted's detected operations, open **View → File System Support**.
The complete audited matrix is in
[docs/filesystem-matrix.md](docs/filesystem-matrix.md).

On RHEL 10, NTFS partition move support requires `ntfsprogs` because that package
provides `ntfsresize`.  The RPM recommends both `ntfsprogs` and `ntfs-3g`.

exFAT support requires `exfatprogs`.  GParted 1.8.1 can create, move, copy,
check, label, and change the UUID of an unmounted exFAT file system.  Upstream
does not implement in-place exFAT grow or shrink; moving a same-size partition
must not be confused with resizing it.

## Important RHEL 10 limitation

RHEL does not ship a Btrfs kernel driver.  With `btrfs-progs`, GParted can
inspect, check, copy, and move an unmounted Btrfs partition, but Btrfs grow and
shrink operations that require mounting the file system remain unavailable.
See [docs/filesystem-support.md](docs/filesystem-support.md).

## Simplified Chinese

The upstream package contains a complete Simplified Chinese message catalog.
If a Chinese desktop still launches GParted in English, check `LC_ALL` first:
it overrides `LANG` and `LC_MESSAGES`.  The optional
`scripts/run-gparted-zh.sh` launcher clears that override and starts the
installed `/usr/bin/gparted` with `zh_CN.UTF-8` messages.  It is not installed
by the RPM and does not replace system locale policy.

## Security and data safety

The build scripts do not run GParted or modify disks.  Partition editing can
cause data loss because of software bugs, hardware failure, or power loss.
Back up data before applying any operation and prefer a supported Live system
when editing operating-system partitions.

Local builds and GitHub Actions release assets are not RPM-signed. A future
signed repository would require a managed RPM signing key or a build service
such as COPR that signs packages and repository metadata.

## Provenance and licenses

The packaging and helper scripts in this repository are MIT licensed.
GParted itself is licensed under GPL-2.0-or-later.  The bundled public key is
the release-signing key for Curtis Gedak, fingerprint:

```text
BB09 FFB8 7563 FA2E 1A22 1468 17A6 D3FF 338C 9570
```

- Upstream: <https://gparted.org>
- Upstream repository: <https://gitlab.gnome.org/GNOME/gparted>
- Fedora package: <https://packages.fedoraproject.org/pkgs/gparted/gparted/>
