set -o errexit
set -o pipefail
set -o nounset

echo ""
echo ">>> Install LLVM 16 for having clang, clang++ to build scalehls"
echo ""


# The absolute path to the directory of this script. (not used)
BUILD_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Project root dir (i.e. polsca/)
POLSCA_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../ && pwd )"


# Go to the llvm directory and carry out installation.
LLVM_16_SRC_DIR="${POLSCA_ROOT_DIR}/llvm-16-src"



# Set your build folder name
BUILD_FOLDER_NAME="llvm-16-src-build"
INSTALLATION_FOLDER_NAME="${BUILD_FOLDER_NAME}-installation"


BUILD_FOLDER_DIR="${POLSCA_ROOT_DIR}/${BUILD_FOLDER_NAME}"
INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"

rm -Rf "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
# rm -Rf "${BUILD_FOLDER_DIR}"

# Create the build folders in $POLSCA_ROOT_DIR
mkdir -p "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
# mkdir -p "${BUILD_FOLDER_DIR}"

cd "${BUILD_FOLDER_DIR}"/


cmake   \
    -G Ninja    \
    -S "${LLVM_16_SRC_DIR}/llvm"  \
    -B .    \
    -DCMAKE_BUILD_TYPE=Release      \
	-DCMAKE_INSTALL_PREFIX="${INSTALLATION_FOLDER_DIR}"  \
    -DLLVM_ENABLE_PROJECTS="mlir;clang;lld;lldb" \
    -DLLVM_INSTALL_UTILS=ON     \
    -DCMAKE_C_COMPILER=gcc    \
    -DCMAKE_CXX_COMPILER=g++    \
    -DLLVM_TARGETS_TO_BUILD="Native"



cmake --build .

# If you want to "install" to "${INSTALLATION_FOLDER_DIR}" dir (means, collecting the "include", "lib", and "bin" dirs to "${INSTALLATION_FOLDER_DIR}"), activate "ninja install".
# ninja install