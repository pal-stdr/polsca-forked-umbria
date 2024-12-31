
# Please use -DLLVM_PARALLEL_LINK_JOBS=2 so that your build doesn't crash because of the RAM overflow
# https://reviews.llvm.org/D72402
# With ld as a linker (version: 2.33.1) ==== (Doesn't work)
# -DLLVM_PARALLEL_LINK_JOBS=any => out of memory
# -DLLVM_PARALLEL_LINK_JOBS=5 => no more than 30 GB memory
# -DLLVM_PARALLEL_LINK_JOBS=2 => no more than 14 GB memory
# -DLLVM_PARALLEL_LINK_JOBS=1 => no more than 10 GB memory

# With lld as a linker (version: 2.33.1) => -DLLVM_USE_LINKER=lld
# ====

# -DLLVM_PARALLEL_LINK_JOBS=any => no more then 9 GB memory (Doesn't work)
# -DLLVM_PARALLEL_LINK_JOBS=2 => no more than 6 GB memory

# The current defaults for LLVM_PARALLEL_LINK_JOBS is empty, meaning any number (only limited by ninja/make parallel option).

# The LLVM_PARALLEL_LINK_JOBS=2 is a better default option, if the linker is not lld.



set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Install LLVM 16 for Scalehls"
echo ""


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
SCALEHLS_POLYGEIST_LLVM_DIR="${POLSCA_ROOT_DIR}/scalehls-umbria-forked/polygeist/llvm-project"


# Go to the llvm directory and carry out installation.
POLYGEIST_LLVM_BUILD_DIR="${POLSCA_ROOT_DIR}/llvm-14-src-build-for-polygeist-polymer-polsca"


# Set your build folder name
BUILD_FOLDER_NAME="llvm-16-src-build-for-scalehls"
INSTALLATION_FOLDER_NAME="${BUILD_FOLDER_NAME}-installation"


BUILD_FOLDER_DIR="${POLSCA_ROOT_DIR}/${BUILD_FOLDER_NAME}"
# INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"


# rm -Rf "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
rm -Rf "${BUILD_FOLDER_DIR}"

# Create the build folders in $POLSCA_ROOT_DIR
# mkdir -p "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
mkdir -p "${BUILD_FOLDER_DIR}"


cd "${BUILD_FOLDER_DIR}"/



# Works
cmake   \
    -G Ninja    \
    -S "${SCALEHLS_POLYGEIST_LLVM_DIR}/llvm"  \
    -B .    \
    -DCMAKE_BUILD_TYPE=DEBUG      \
    -DLLVM_ENABLE_PROJECTS="mlir;clang;lld" \
    -DLLVM_TARGETS_TO_BUILD="host" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DMLIR_ENABLE_BINDINGS_PYTHON="${PYBIND:=OFF}" \
    -DSCALEHLS_ENABLE_BINDINGS_PYTHON="${PYBIND:=OFF}" \
    -DLLVM_PARALLEL_LINK_JOBS=2 \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++    \
    -DLLVM_USE_LINKER=lld



# # Works (With installation dir)
# cmake   \
#     -G Ninja    \
#     -S "${SCALEHLS_POLYGEIST_LLVM_DIR}/llvm"  \
#     -B .    \
#     -DCMAKE_BUILD_TYPE=DEBUG      \
#     -DCMAKE_INSTALL_PREFIX="${INSTALLATION_FOLDER_DIR}"  \
#     -DLLVM_ENABLE_PROJECTS="mlir;clang;lld" \
#     -DLLVM_TARGETS_TO_BUILD="host" \
#     -DLLVM_ENABLE_ASSERTIONS=ON \
#     -DMLIR_ENABLE_BINDINGS_PYTHON="${PYBIND:=OFF}" \
#     -DSCALEHLS_ENABLE_BINDINGS_PYTHON="${PYBIND:=OFF}" \
#     -DLLVM_PARALLEL_LINK_JOBS=2 \
#     -DCMAKE_C_COMPILER=clang \
#     -DCMAKE_CXX_COMPILER=clang++    \
#     -DLLVM_USE_LINKER=lld



# Run build
cmake --build .
ninja install
