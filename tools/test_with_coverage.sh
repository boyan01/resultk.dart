#!/bin/sh

set -e o pipefail

(pub global list | grep coverage) || {
  # install coverage when not found
  pub global activate coverage
}

OBS_PORT=9292
pub global run coverage:collect_coverage \
    --port=$OBS_PORT \
    --out=out/coverage/coverage.json \
    --wait-paused \
    --resume-isolates \
    &

dart \
    --disable-service-auth-codes \
    --enable-vm-service=$OBS_PORT \
    --pause-isolates-on-exit  \
    --enable-asserts \
    test/result_test.dart

pub global run coverage:format_coverage \
    --lcov \
    --in=out/coverage/coverage.json \
    --out=out/coverage/lcov.info \
    --packages=.packages \
    --report-on lib