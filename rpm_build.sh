#!/bin/bash

set -e

first_changelog_line=$(head -n 1 debian/changelog)
RPM_NAME=$(echo "$first_changelog_line" | awk '{print $1}')
VERSION=$(echo "$first_changelog_line" | awk '{print $2}' | tr -d '()')
EXEC_DIR=$(pwd)
PY_INTERPRETER="${PY_INTERPRETER:-/usr/bin/python3.11}"
PACKAGE=$(awk -F'"' '/^name = / { print $2; exit }' pyproject.toml)
RPM_BUILD_DIR="${RPM_BUILD_DIR:-/var/tmp/$PACKAGE-rpmbuild}"
VENV_PATH="/var/lib/nmexec/venv"
MODELS_DIR="yoloModels"
TAR_CMD="${TAR_CMD:-bsdtar}"

export UV_NO_CACHE=1

if [ ! -x "$PY_INTERPRETER" ]; then
    echo "Python interpreter not found or not executable: $PY_INTERPRETER" >&2
    exit 1
fi

if ! command -v "$TAR_CMD" >/dev/null 2>&1; then
    echo "Required archive tool not found: $TAR_CMD" >&2
    echo "Install bsdtar/libarchive or set TAR_CMD to another tar-compatible command." >&2
    exit 1
fi

rm -rf "$RPM_BUILD_DIR"
rm -rf "$VENV_PATH"
rm -rf dist

mkdir -p "$RPM_BUILD_DIR/BUILD"
mkdir -p "$RPM_BUILD_DIR/BUILDROOT"
mkdir -p "$RPM_BUILD_DIR/RPMS"
mkdir -p "$RPM_BUILD_DIR/SOURCES"
mkdir -p "$RPM_BUILD_DIR/SPECS"
mkdir -p "$RPM_BUILD_DIR/SRPMS"

"$PY_INTERPRETER" -m pip install --upgrade build uv
"$PY_INTERPRETER" -m build --wheel

"$PY_INTERPRETER" -m venv "$VENV_PATH"
"$VENV_PATH/bin/python" -m pip install -U uv
"$VENV_PATH/bin/python" -m uv pip install -U dist/*.whl

"$TAR_CMD" -zcf "$RPM_BUILD_DIR/SOURCES/$PACKAGE.tar.gz" -C "$VENV_PATH" .
"$TAR_CMD" -zcf "$RPM_BUILD_DIR/SOURCES/$MODELS_DIR.tar.gz" "$MODELS_DIR"
cp nmexec.service "$RPM_BUILD_DIR/SOURCES/"
cp nmexec.conf "$RPM_BUILD_DIR/SOURCES/"
cp "rpm/$RPM_NAME.spec" "$RPM_BUILD_DIR/SPECS/"

rpmbuild -bb --define "_version $VERSION" --define "_rpmdir $RPM_BUILD_DIR/RPMS" --define "_sourcedir $RPM_BUILD_DIR/SOURCES" --define "_topdir $RPM_BUILD_DIR" "$RPM_BUILD_DIR/SPECS/$RPM_NAME.spec"

mv "$RPM_BUILD_DIR"/RPMS/*/*.rpm "$EXEC_DIR/"

rm -rf "$RPM_BUILD_DIR"
rm -rf "$VENV_PATH"
rm -rf dist

exit 0
