set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Install Scalehls "
echo ""

# ------------------------- Environment --------------------------

# The absolute path to the directory of this script. (not used)
BUILD_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Project root dir (i.e. polsca/)
POLSCA_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../ && pwd )"




# Mandatory for building llvm with clang 16.
# You need all the clang bin and lib in env
LLVM_16_BUILD_DIR="${POLSCA_ROOT_DIR}/llvm-16-src-build"
LLVM_16_BUILD_LIB_DIR="${LLVM_16_BUILD_DIR}/lib"
LLVM_16_BUILD_BIN_DIR="${LLVM_16_BUILD_DIR}/bin"

export LD_LIBRARY_PATH="${LLVM_16_BUILD_LIB_DIR}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="${LLVM_16_BUILD_BIN_DIR}${PATH:+:${PATH}}"




# Go to the llvm directory and carry out installation.
POLYGEIST_LLVM_BUILD_DIR="${POLSCA_ROOT_DIR}/llvm-16-src-build-for-scalehls"
CLANG_BUILD_DIR="${POLSCA_ROOT_DIR}/llvm-14-src-build-for-polygeist-polymer-polsca"


# Scalehls src dir
SCALEHLS_DIR="${POLSCA_ROOT_DIR}/scalehls-umbria-forked"

# Set Polymer build folder name
BUILD_FOLDER_NAME="scalehls-build"
INSTALLATION_FOLDER_NAME="${BUILD_FOLDER_NAME}-installation"

# Create the build folders in $POLSCA_ROOT_DIR
BUILD_FOLDER_DIR="${POLSCA_ROOT_DIR}/${BUILD_FOLDER_NAME}"
INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"


rm -Rf "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
mkdir -p "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
cd "${BUILD_FOLDER_DIR}"/



cmake   \
    -G Ninja    \
    -S "${SCALEHLS_DIR}"  \
    -B .    \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX="${INSTALLATION_FOLDER_DIR}"  \
    -DLLVM_PARALLEL_LINK_JOBS=2 \
    -DMLIR_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/mlir" \
    -DLLVM_DIR="${POLYGEIST_LLVM_BUILD_DIR}/lib/cmake/llvm" \
    -DLLVM_EXTERNAL_LIT="${POLYGEIST_LLVM_BUILD_DIR}/bin/llvm-lit"	\
	-DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++	\
    -DLLVM_USE_LINKER=lld



cmake --build . --target check-scalehls
ninja install
