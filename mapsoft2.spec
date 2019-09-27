Name:         mapsoft2
Version:      0.1
Release:      alt1

Summary:      mapsoft2 - programs for working with maps and geodata
Group:        Sciences/Geosciences
Url:          http://github.org/slazav/mapsoft2
Packager:     Vladislav Zavjalov <slazav@altlinux.org>
License:      GPL3.0

Source:        %name-%version.tar

BuildRequires: gcc-c++ libgtkmm3-devel libcairomm-devel
BuildRequires: libjansson-devel libxml2-devel libzip-devel zlib-devel libproj-devel
BuildRequires: libjpeg-devel libgif-devel libtiff-devel libpng-devel
BuildRequires: m4 /usr/bin/pod2man

%description
mapsoft2 - programs for working with maps and geodata

%prep
%setup -q

%build
%make

%install
%makeinstall initdir=%buildroot%_initdir

%files
%_bindir/ms2*
%_mandir/man1/ms2*
%_mandir/man5/mapsoft2*
%_datadir/mapsoft2/mapsoft2.css

%changelog
