#!/usr/bin/env bash
set -euo pipefail

bash -n scripts/de_tuan.sh
test -f README.md
test -f diagrams/de_tuan_flow.puml

echo "Kiem tra De Tuan thanh cong."
