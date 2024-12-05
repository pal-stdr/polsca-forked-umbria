#!/usr/bin/env bash
# This script installs the Polymer repository.
# Actual polymer support for polsca is 585dc6f10b77860ec9a0cece22e263ce74753a48 (Oct 21, 2021)
# polymer commit (Kumasento Polymer src)- 747b4f34cb348eae361b6705f7f5bb0f9997f88a (Dec 1, 2021)


set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Build + Install Polymer for Umbria"
echo ""


# The absolute path to the directory of this script.
BUILD_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Project root dir (i.e. polsca/)
POLSCA_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../ && pwd )"


# Go to the llvm directory and carry out installation.
POLYGEIST_LLVM_BUILD_DIR="${POLSCA_ROOT_DIR}/llvm-14-src-build-for-polygeist-polymer-polsca"


# This is mandatory to satify pluto's "pet-for-pluto" clang dependency.
PLUTO_LIBCLANG_PREFIX_DIR="${POLSCA_ROOT_DIR}/llvm-9-src-build-for-polymer-pluto-installation"


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
	-DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DMLIR_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/mlir" \
    -DLLVM_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/llvm" \
    -DLLVM_EXTERNAL_LIT="${POLYGEIST_LLVM_BUILD_DIR}/bin/llvm-lit" \
    -DPLUTO_LIBCLANG_PREFIX="${PLUTO_LIBCLANG_PREFIX_DIR}"  \
    -DLLVM_ENABLE_ASSERTIONS=ON


# Mandatory for avoiding regression test failure (libosl.so.0 linker error)
export LD_LIBRARY_PATH="${BUILD_FOLDER_DIR}/pluto/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"


# Run build
cmake --build . --target check-polymer
ninja install
