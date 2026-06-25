#!/bin/bash

set -e

first_changelog_line=$(head -n 1 debian/changelog)
RPM_NAME=$(echo "$first_changelog_line" | awk '{print $1}')
VERSION=$(echo "$first_changelog_line" | awk '{print $2}' | tr -d '()')
EXEC_DIR=$(pwd)
RPM_BUILD_DIR=$EXEC_DIR/rpmbuild
PY_INTERPRETER="python3.11"
PACKAGE=$(awk -F'"' '/^name = / { print $2; exit }' pyproject.toml)
VENV_PATH="/var/lib/nmexec/venv"
SOURCE_STAGE_DIR="$EXEC_DIR/$RPM_NAME-$VERSION"

export UV_NO_CACHE=1

rm -rf "$RPM_BUILD_DIR"
rm -rf "$SOURCE_STAGE_DIR"
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

mkdir -p "$SOURCE_STAGE_DIR"
cp nmexec.service "$SOURCE_STAGE_DIR/"
cp nmexec.conf "$SOURCE_STAGE_DIR/"
tar -zcf "$SOURCE_STAGE_DIR/$PACKAGE.tar.gz" -C "$VENV_PATH" .
tar -zcf "$RPM_NAME-$VERSION.tar.gz" -C "$EXEC_DIR" "$RPM_NAME-$VERSION"

mv "$RPM_NAME-$VERSION.tar.gz" "$RPM_BUILD_DIR/SOURCES/"
cp "rpm/$RPM_NAME.spec" "$RPM_BUILD_DIR/SPECS/"

rpmbuild -bb --define "_version $VERSION" --define "_rpmdir $RPM_BUILD_DIR/RPMS" --define "_sourcedir $RPM_BUILD_DIR/SOURCES" --define "_topdir $RPM_BUILD_DIR/BUILDROOT" "$RPM_BUILD_DIR/SPECS/$RPM_NAME.spec"

mv "$RPM_BUILD_DIR"/RPMS/*/*.rpm "$EXEC_DIR/"

rm -rf "$RPM_BUILD_DIR"
rm -rf "$SOURCE_STAGE_DIR"
rm -rf "$VENV_PATH"
rm -rf dist

exit 0
