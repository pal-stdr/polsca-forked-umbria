#!/usr/bin/env bash
# This script installs the Polymer repository.
# polymer commit- 5d4ec7335606a87a6aead1153adfcb21257e99d3


set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Install Polymer for Umbria"
echo ""


# The absolute path to the directory of this script.
BUILD_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Project root dir (i.e. polsca/)
POLSCA_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../ && pwd )"


# Go to the llvm directory and carry out installation.
POLYGEIST_LLVM_BUILD_DIR="${POLSCA_ROOT_DIR}/llvm-build-for-polygeist-polymer-polsca"


# Set Polymer build folder name
BUILD_FOLDER_NAME="polymer-build-for-polsca"
INSTALLATION_FOLDER_NAME="${BUILD_FOLDER_NAME}-installation"

# Create the build folders in $POLSCA_ROOT_DIR
BUILD_FOLDER_DIR="${POLSCA_ROOT_DIR}/${BUILD_FOLDER_NAME}"
INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"


rm -Rf "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
mkdir -p "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
cd "${BUILD_FOLDER_DIR}"/


cmake   \
    -G Ninja    \
    -S "${POLSCA_ROOT_DIR}/polymer"  \
    -B .    \
    -DCMAKE_BUILD_TYPE=DEBUG \
    -DCMAKE_INSTALL_PREFIX="${INSTALLATION_FOLDER_DIR}"  \
    -DMLIR_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/mlir" \
    -DLLVM_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/llvm" \
    -DLLVM_EXTERNAL_LIT="${POLYGEIST_LLVM_BUILD_DIR}/bin/llvm-lit" \
    -DLLVM_ENABLE_ASSERTIONS=ON


# Mandatory for avoiding regression test failure (libosl.so.0 linker error)
export LD_LIBRARY_PATH="$PWD/pluto/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"


# Run build
cmake --build . --target check-polymer
ninja install
