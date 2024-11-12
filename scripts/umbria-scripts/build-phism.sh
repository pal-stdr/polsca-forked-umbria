#!/usr/bin/env bash

# ----------- Install Phism (experimental) --------------
# It is not guaranteed to work seamlessly on any machine. Do check the
# exact commands it runs if anything wrong happens, and post the error
# messages here: https://github.com/kumasento/phism/issues

set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Install Phism "
echo ""

# ------------------------- Environment --------------------------

# The absolute path to the directory of this script. (not used)
BUILD_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Project root dir (i.e. polsca/)
POLSCA_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../ && pwd )"


# Go to the llvm directory and carry out installation.
POLYGEIST_LLVM_BUILD_DIR="${POLSCA_ROOT_DIR}/llvm-14-src-build-for-polygeist-polymer-polsca"


# Set Polymer build folder name
BUILD_FOLDER_NAME="polsca-build"
INSTALLATION_FOLDER_NAME="${BUILD_FOLDER_NAME}-installation"

# Create the build folders in $POLSCA_ROOT_DIR
BUILD_FOLDER_DIR="${POLSCA_ROOT_DIR}/${BUILD_FOLDER_NAME}"
INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"


rm -Rf "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
mkdir -p "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
cd "${BUILD_FOLDER_DIR}"/


# ------------------------- CMake Configure ---------------------

cmake   \
    -G Ninja    \
    -S "${POLSCA_ROOT_DIR}"  \
    -B .    \
    -DCMAKE_BUILD_TYPE=DEBUG \
    -DCMAKE_INSTALL_PREFIX="${INSTALLATION_FOLDER_DIR}"  \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DMLIR_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/mlir" \
    -DLLVM_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/llvm" \
    -DLLVM_EXTERNAL_LIT="${POLYGEIST_LLVM_BUILD_DIR}/bin/llvm-lit" \
	-DLLVM_ENABLE_ASSERTIONS=ON





# ------------------------- Build and test ---------------------

cmake --build . --target check-phism
ninja install