#!/bin/bash

set -e

PY_INTERPRETER="python3.11"
PACKAGE=$(awk -F'"' '/^name = / { print $2; exit }' pyproject.toml)
VENV_PATH="/var/lib/nmexec/venv"
STAGING_DIR="debian-files/usr/share/sde_venvs"

rm -rf debian-files
rm -rf "$VENV_PATH"
rm -rf dist

mkdir -p "$STAGING_DIR"

"$PY_INTERPRETER" -m pip install build uv
"$PY_INTERPRETER" -m build --wheel

"$PY_INTERPRETER" -m venv "$VENV_PATH"
"$VENV_PATH/bin/python" -m pip install -U uv
"$VENV_PATH/bin/python" -m uv pip install -U dist/*.whl

tar -zcf "$STAGING_DIR/$PACKAGE.tar.gz" -C "$VENV_PATH" .

rm -rf "$VENV_PATH"
rm -rf dist

debuild -b -us -uc
mv ../*.deb .

exit 0
