%if 0%{?_version:1}
%define version %{_version}
%endif

Name:           nmexec
Version:        %{version}
Release:        1%{?dist}
Summary:        Network Model Executor
BuildArch:      x86_64

License:        MIT
Source0:        %{name}.tar.gz
Source1:        nmexec.service
Source2:        nmexec.conf

Requires:       python3.11

%global pyname nmexec
%global program nmexec
%global debug_package %{nil}

%description
Network Model Executor Allows to process data over the network

%prep
:

%build
:

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/share/sde_venvs
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system
mkdir -p $RPM_BUILD_ROOT/etc/supervisor/conf.d

cp %{SOURCE0} $RPM_BUILD_ROOT/usr/share/sde_venvs/%{pyname}.tar.gz
cp %{SOURCE1} $RPM_BUILD_ROOT/etc/systemd/system/nmexec.service
cp %{SOURCE2} $RPM_BUILD_ROOT/etc/supervisor/conf.d/nmexec.conf

%files
/usr/share/sde_venvs/%{pyname}.tar.gz
/etc/systemd/system/nmexec.service
/etc/supervisor/conf.d/nmexec.conf

%clean
rm -rf $RPM_BUILD_ROOT

%post
# Create nmexec group if it doesn't exist
if ! getent group nmexec > /dev/null; then
    groupadd --system nmexec
fi
# Create nmexec user if it doesn't exist
if ! getent passwd nmexec > /dev/null; then
    useradd --system --gid nmexec --home /var/lib/nmexec --shell /bin/bash nmexec
fi

mkdir -p /var/lib/nmexec
rm -rf /var/lib/nmexec/venv
mkdir -p /var/lib/nmexec/venv
tar -zxf /usr/share/sde_venvs/%{pyname}.tar.gz -C /var/lib/nmexec/venv
rm -f /usr/share/sde_venvs/%{pyname}.tar.gz

# Create shared symlink for yolo9 so other services can access it
ln -s -f "/var/lib/nmexec/venv/bin/nmexec" /usr/local/bin/nmexec
ln -s -f "/var/lib/nmexec/venv/bin/yolo9_train_dual" /usr/local/bin/yolo9_train_dual
ln -s -f "/var/lib/nmexec/venv/bin/yolo9_detect" /usr/local/bin/yolo9_detect
ln -s -f "/var/lib/nmexec/venv/bin/yolo9_val_dual" /usr/local/bin/yolo9_val_dual

chown -R nmexec:nmexec /var/lib/nmexec

if command -v supervisorctl >/dev/null 2>&1; then
    echo "Using supervisor"
    supervisorctl reread || echo "Could not reread supervisor"
    supervisorctl update || echo "Could not update supervisor"
    supervisorctl restart nmexec || echo "Could not restart nmexec"
    rm -rf /etc/systemd/system/nmexec.service
else
    echo "Configuring nmexec"
    systemctl daemon-reload
    systemctl enable nmexec.service
    systemctl start nmexec.service
    systemctl restart nmexec.service
    rm -rf /etc/supervisor/conf.d/nmexec.conf
fi

%preun
if [ "$1" -eq 0 ] || [ "$1" -eq 1 ]; then
    if command -v supervisorctl >/dev/null 2>&1; then
        supervisorctl stop nmexec || true
    else
        systemctl stop nmexec.service || true
    fi
fi

if [ "$1" -eq 0 ]; then
    if command -v supervisorctl >/dev/null 2>&1; then
        rm -f /etc/supervisor/conf.d/nmexec.conf
        supervisorctl reread || true
        supervisorctl update || true
    else
        systemctl disable nmexec.service || true
        systemctl daemon-reload || true
    fi

    pkill -u nmexec || true

    userdel nmexec || true
    groupdel nmexec || true

    rm -rf /var/lib/nmexec/venv

    # Remove symlinks
    rm -f /usr/local/bin/nmexec
    rm -f /usr/local/bin/yolo9_train_dual
    rm -f /usr/local/bin/yolo9_detect
    rm -f /usr/local/bin/yolo9_val_dual
fi

%postun
if [ "$1" -eq 0 ]; then
    if command -v supervisorctl >/dev/null 2>&1; then
        supervisorctl reread || true
        supervisorctl update || true
    else
        systemctl daemon-reload || true
    fi
fi

%changelog
* Tue Jun 25 2024 Alejandro Alfonso <alejandro@sorba.ai> - 1.0.9-1
- Initial rpm release
