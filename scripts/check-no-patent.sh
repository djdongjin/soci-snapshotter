#!/bin/bash

#   Copyright The containerd Authors.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Copied from https://github.com/containerd/stargz-snapshotter/blob/v0.14.1/script/util/verify-no-patent.sh
# (which is copied from https://github.com/containerd/nerdctl/blob/v1.1.0/hack/verify-no-patent.sh)
# Modified for soci snapshotter project

echo "Verifying that the patented NewARC() is NOT compiled in (https://github.com/hashicorp/golang-lru/blob/v0.5.4/arc.go#L15)"
set -eux -o pipefail

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOCI_SNAPSHOTTER_PROJECT_ROOT="${CUR_DIR}/.."

# Clear GO_BUILD_LDFLAGS to embed the symbols
(cd $SOCI_SNAPSHOTTER_PROJECT_ROOT && GO_BUILD_LDFLAGS="" make)

for O in soci soci-snapshotter-grpc ; do
    go tool nm $SOCI_SNAPSHOTTER_PROJECT_ROOT/out/$O >$SOCI_SNAPSHOTTER_PROJECT_ROOT/out/$O.sym

    if ! grep -w -F main.main ${SOCI_SNAPSHOTTER_PROJECT_ROOT}/out/$O.sym; then
	echo >&2 "ERROR: the symbol file seems corrupted"
	exit 1
    fi

    if grep -w NewARC ${SOCI_SNAPSHOTTER_PROJECT_ROOT}/out/$O.sym; then
	echo >&2 "ERROR: patented NewARC() might be compiled in?"
	exit 1
    fi
done

echo "OK"