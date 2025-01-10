#!/usr/bin/env bash
# This script installs the llvm shipped together with Phism.
# polygeist/llvm-project commit (clang version 14.0.0)- 30d87d4a5d02f00ef58ebc24a0ee5c6c370b8b4c
# polygeist commit- 2e6bb368ff4894993eb2102c1da3389fa18e49ef
# Doc: https://releases.llvm.org/14.0.0/docs
# Polly Doc: https://releases.llvm.org/14.0.0/tools/polly/docs/UsingPollyWithClang.html


set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Install LLVM for Umbria"
echo ""

# The absolute path to the directory of this script. (not used)
BUILD_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Project root dir (i.e. polsca/)
POLSCA_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../ && pwd )"

# Go to the llvm directory and carry out installation.
POLYGEIST_LLVM_DIR="${POLSCA_ROOT_DIR}/polygeist/llvm-project"


# Set your build folder name
BUILD_FOLDER_NAME="llvm-14-src-build-for-polygeist-polymer-polsca"
INSTALLATION_FOLDER_NAME="${BUILD_FOLDER_NAME}-installation"


BUILD_FOLDER_DIR="${POLSCA_ROOT_DIR}/${BUILD_FOLDER_NAME}"
INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"


rm -Rf "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"

# Create the build folders in $POLSCA_ROOT_DIR
mkdir -p "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"

cd "${BUILD_FOLDER_DIR}"/


echo $POLYGEIST_LLVM_DIR
echo $BUILD_FOLDER_DIR


cmake   \
    -G Ninja    \
    -S "${POLYGEIST_LLVM_DIR}/llvm"  \
    -B .    \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_INSTALL_PREFIX="${INSTALLATION_FOLDER_DIR}"  \
    -DLLVM_ENABLE_PROJECTS="clang;mlir;lld;polly;openmp" \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_INSTALL_UTILS=ON     \
    -DCMAKE_C_COMPILER=gcc    \
    -DCMAKE_CXX_COMPILER=g++    \
    -DLLVM_TARGETS_TO_BUILD="host"    \
    -DLLVM_BUILD_EXAMPLES=OFF \
	-DLLVM_ENABLE_ASSERTIONS=ON




# Run build
cmake --build . --target check-mlir check-polly check-clang check-lld check-openmp

# # If you want to "install" to "${INSTALLATION_FOLDER_DIR}" dir (means, collecting the "include", "lib", and "bin" dirs to "${INSTALLATION_FOLDER_DIR}"), activate "ninja install".
# ninja install