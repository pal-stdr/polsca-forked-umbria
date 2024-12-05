#!/usr/bin/env bash

# ----------- Install Phism (experimental) --------------
# It is not guaranteed to work seamlessly on any machine. Do check the
# exact commands it runs if anything wrong happens, and post the error
# messages here: https://github.com/kumasento/phism/issues

set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Install Papi (tag: papi-7-1-0-t) in the project root "
echo ""

# ------------------------- Environment --------------------------

# The absolute path to the directory of this script. (not used)
BUILD_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Project root dir (i.e. polsca/)
POLSCA_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../ && pwd )"


# Go to the llvm directory and carry out installation.
PAPI_ROOT_DIR="${POLSCA_ROOT_DIR}/papi"


# Set PAPI prefix (i.e. installation) path
INSTALLATION_FOLDER_NAME="papi-7-1-0-t-installation"

# Create the build folders in $POLSCA_ROOT_DIR
INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"

# papi build asset dumping path
PREFIX_PATH="${INSTALLATION_FOLDER_DIR}"


# Set the perf_event_paranoid from 4 to 0. Neither you will get error
echo 0 | sudo tee /proc/sys/kernel/perf_event_paranoid


rm -Rf "${INSTALLATION_FOLDER_DIR}"
mkdir -p "${INSTALLATION_FOLDER_DIR}"
cd "${PAPI_ROOT_DIR}/src"

./configure --prefix="${PREFIX_PATH}"

make -j $(nproc)

make install