#!/usr/bin/env bash

set -euo pipefail

for test_script in tests/*.sh; do
    if [ "${test_script}" = "tests/run.sh" ]; then
        continue
    fi
    echo "[I] Running ${test_script}..."
    "${test_script}"
done

