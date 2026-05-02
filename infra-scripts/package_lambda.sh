#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/dist"

mkdir -p "${OUTPUT_DIR}"

cd "${REPO_ROOT}/lambda"
python3 -m zipfile -c "${OUTPUT_DIR}/trigger_glue.zip" "trigger_glue.py"

echo "Created Lambda package at ${OUTPUT_DIR}/trigger_glue.zip"
