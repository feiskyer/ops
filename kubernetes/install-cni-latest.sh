#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE}")
source ${REPO_ROOT}/lib/util.sh
source ${REPO_ROOT}/lib/cni.sh

install-cni-src
config-cni-list
