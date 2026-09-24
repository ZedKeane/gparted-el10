%global use_source_date_epoch_as_buildtime 1

Summary:        GNOME Partition Editor
Name:           gparted
Version:        1.8.1
Release:        2%{?dist}
License:        GPL-2.0-or-later
URL:            https://gparted.org
Source0:        https://downloads.sourceforge.net/%{name}/%{name}-%{version}.tar.gz

BuildRequires:  gtkmm3.0-devel
BuildRequires:  parted-devel
BuildRequires:  libuuid-devel
BuildRequires:  gettext
BuildRequires:  perl(XML::Parser)
BuildRequires:  desktop-file-utils
BuildRequires:  intltool
BuildRequires:  pkgconfig
BuildRequires:  polkit-devel
BuildRequires:  polkit
BuildRequires:  libappstream-glib
BuildRequires:  itstool
BuildRequires:  yelp-tools
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  weston

# Prevent helper integration tests from silently skipping.
BuildRequires:  btrfs-progs
BuildRequires:  dosfstools
BuildRequires:  e2fsprogs
BuildRequires:  exfatprogs
BuildRequires:  mtools
BuildRequires:  ntfsprogs
BuildRequires:  util-linux
BuildRequires:  xfsdump
BuildRequires:  xfsprogs

Requires:       PolicyKit-authentication-agent
Requires:       xhost

# File-system helpers are detected at run time.
Recommends:     btrfs-progs
Recommends:     cryptsetup
Recommends:     dosfstools
Recommends:     e2fsprogs
Recommends:     exfatprogs
Recommends:     lvm2
Recommends:     mdadm
Recommends:     mtools
Recommends:     ntfs-3g
Recommends:     ntfsprogs
Recommends:     util-linux
Recommends:     xfsprogs
Recommends:     xfsdump

%description
GParted is the GNOME Partition Editor, a graphical front end to libparted.
It can create, delete, resize, move, check, label, copy, and paste partitions.
Support for individual file-system operations is detected from helper tools
available at run time.

This package is adapted from Fedora's GParted packaging for RHEL 10 and
compatible distributions.  It does not add Btrfs kernel support to RHEL.

%prep
%autosetup -p1

%build
%configure \
    --enable-libparted-dmraid \
    --enable-xhost-root
%make_build

%check
test_runtime=$(mktemp -d)
chmod 700 "$test_runtime"
XDG_RUNTIME_DIR="$test_runtime" \
    weston --backend=headless --socket=gparted-test \
           --idle-time=0 --log="$test_runtime/weston.log" &
weston_pid=$!
trap 'kill "$weston_pid" 2>/dev/null || :; find "$test_runtime" -depth -delete' EXIT

for attempt in $(seq 1 100); do
    test -S "$test_runtime/gparted-test" && break
    sleep 0.1
done
test -S "$test_runtime/gparted-test" || {
    cat "$test_runtime/weston.log"
    exit 1
}

DISPLAY=:99 \
GDK_BACKEND=wayland \
WAYLAND_DISPLAY=gparted-test \
XDG_RUNTIME_DIR="$test_runtime" \
    %make_build check

require_fs_tests() {
    fs_name=$1
    shift
    for test_name in "$@"; do
        grep -Eq "\\[ +OK +\\].*${test_name}/${fs_name}" \
            tests/test_SupportedFileSystems.log
    done
}

require_fs_tests btrfs \
    Create \
    CreateAndReadUsage \
    CreateAndReadLabel \
    CreateAndReadUUID \
    CreateAndWriteLabel \
    CreateAndWriteUUID \
    CreateAndWriteUUIDAndReadLabel \
    CreateAndCheck

for fs_name in ext2 ext3 ext4; do
    require_fs_tests "$fs_name" \
        Create \
        CreateAndReadUsage \
        CreateAndReadLabel \
        CreateAndReadUUID \
        CreateAndWriteLabel \
        CreateAndWriteUUID \
        CreateAndWriteUUIDAndReadLabel \
        CreateAndCheck \
        CreateAndGrow \
        CreateAndShrink
done

require_fs_tests exfat \
    Create \
    CreateAndReadUsage \
    CreateAndReadLabel \
    CreateAndReadUUID \
    CreateAndWriteLabel \
    CreateAndWriteUUID \
    CreateAndWriteUUIDAndReadLabel \
    CreateAndCheck

for fs_name in fat16 fat32; do
    require_fs_tests "$fs_name" \
        Create \
        CreateAndReadUsage \
        CreateAndReadLabel \
        CreateAndReadUUID \
        CreateAndWriteLabel \
        CreateAndWriteUUID \
        CreateAndWriteUUIDAndReadLabel \
        CreateAndCheck
done

require_fs_tests linuxswap \
    Create \
    CreateAndReadLabel \
    CreateAndReadUUID \
    CreateAndWriteLabel \
    CreateAndWriteUUID \
    CreateAndGrow \
    CreateAndShrink

# Upstream disables the Minix check case; verify creation here and fsck later.
require_fs_tests minix \
    Create

# ntfsresize from ntfsprogs enables NTFS resize and move.
require_fs_tests ntfs \
    Create \
    CreateAndReadUsage \
    CreateAndReadLabel \
    CreateAndWriteUUID \
    CreateAndWriteUUIDAndReadLabel \
    CreateAndWriteLabel \
    CreateAndCheck \
    CreateAndGrow \
    CreateAndShrink

require_fs_tests xfs \
    Create \
    CreateAndReadUsage \
    CreateAndReadLabel \
    CreateAndReadUUID \
    CreateAndWriteLabel \
    CreateAndWriteUUID \
    CreateAndCheck

msgfmt --check --statistics po/zh_CN.po -o /dev/null
if msgattrib --untranslated --no-obsolete po/zh_CN.po | grep -q '^msgid '; then
    echo 'Simplified Chinese catalog contains untranslated messages' >&2
    exit 1
fi
if msgattrib --fuzzy --no-obsolete po/zh_CN.po | grep -q '^msgid '; then
    echo 'Simplified Chinese catalog contains fuzzy messages' >&2
    exit 1
fi

%install
%make_install

sed -i 's#_X-GNOME-FullName#X-GNOME-FullName#' \
    %{buildroot}%{_datadir}/applications/%{name}.desktop
sed -i 's#sbin#bin#' \
    %{buildroot}%{_datadir}/applications/%{name}.desktop

desktop-file-install --delete-original \
    --dir %{buildroot}%{_datadir}/applications \
    --mode 0644 \
    --add-category X-Fedora \
    --add-category GTK \
    %{buildroot}%{_datadir}/applications/%{name}.desktop

install -d %{buildroot}%{_datadir}/metainfo
install -p -m 0644 %{name}.appdata.xml \
    %{buildroot}%{_datadir}/metainfo/%{name}.appdata.xml

appstream-util validate-relax --nonet \
    %{buildroot}%{_datadir}/metainfo/%{name}.appdata.xml

grep -Fqx 'GenericName[zh_CN]=分区编辑器' \
    %{buildroot}%{_datadir}/applications/%{name}.desktop
grep -Fqx 'Comment[zh_CN]=创建、重新组织或删除分区' \
    %{buildroot}%{_datadir}/applications/%{name}.desktop
grep -Fq '<description xml:lang="zh_CN">' \
    %{buildroot}%{_datadir}/polkit-1/actions/org.gnome.gparted.policy
grep -Fq '<message xml:lang="zh_CN">' \
    %{buildroot}%{_datadir}/polkit-1/actions/org.gnome.gparted.policy
test -s %{buildroot}%{_datadir}/locale/zh_CN/LC_MESSAGES/%{name}.mo

%find_lang %{name}

%files -f %{name}.lang
%license COPYING
%doc AUTHORS ChangeLog README
%{_libexecdir}/gpartedbin
%{_bindir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/metainfo/%{name}.appdata.xml
%{_datadir}/icons/hicolor/*/apps/gparted.*
%{_datadir}/polkit-1/actions/org.gnome.gparted.policy
%{_datadir}/help/*/gparted/*
%{_mandir}/man8/gparted.*

%changelog
* Thu Sep 24 2026 ZedKeane - 1.8.1-2
- Initial RHEL 10 package
