#!/usr/bin/env bash
# This script installs the Polygeist repository.

set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Install Polygeist for Umbria"
echo ""

# The absolute path to the directory of this script. (not used)
BUILD_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Project root dir (i.e. polsca/)
POLSCA_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../ && pwd )"


# Go to the llvm directory and carry out installation.
POLYGEIST_LLVM_BUILD_DIR="${POLSCA_ROOT_DIR}/llvm-build-for-polygeist-polymer-polsca"


# Set Polymer build folder name
BUILD_FOLDER_NAME="polygeist-build-for-polsca"
INSTALLATION_FOLDER_NAME="${BUILD_FOLDER_NAME}-installation"

# Create the build folders in $POLSCA_ROOT_DIR
BUILD_FOLDER_DIR="${POLSCA_ROOT_DIR}/${BUILD_FOLDER_NAME}"
INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"


rm -Rf "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
mkdir -p "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
cd "${BUILD_FOLDER_DIR}"/



# clang --version
# clang++ --version

# Configure CMake
cmake   \
    -G Ninja    \
    -S "${POLSCA_ROOT_DIR}/polygeist"  \
    -B .    \
    -DCMAKE_BUILD_TYPE=DEBUG \
    -DCMAKE_INSTALL_PREFIX="${INSTALLATION_FOLDER_DIR}"  \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DMLIR_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/mlir" \
    -DCLANG_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/clang" \
    -DLLVM_TARGETS_TO_BUILD="host" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_BUILD_TYPE=DEBUG

 

# Run build
cmake --build . --target check-mlir-clang
ninja install
