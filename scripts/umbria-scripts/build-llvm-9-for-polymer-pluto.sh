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

# Polymer root dir
POLYMER_ROOT_DIR="${POLSCA_ROOT_DIR}/polymer"


# LLVM-9 dir
LLVM_9_DIR="${POLYMER_ROOT_DIR}/llvm-9-src-for-polymer-pluto/"


# Set llvm-9 build folder name
BUILD_FOLDER_NAME="llvm-9-src-build-for-polymer-pluto"
INSTALLATION_FOLDER_NAME="${BUILD_FOLDER_NAME}-installation"


# Create the build folders in $POLSCA_ROOT_DIR
BUILD_FOLDER_DIR="${POLSCA_ROOT_DIR}/${BUILD_FOLDER_NAME}"
INSTALLATION_FOLDER_DIR="${POLSCA_ROOT_DIR}/${INSTALLATION_FOLDER_NAME}"


rm -Rf "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
mkdir -p "${BUILD_FOLDER_DIR}" "${INSTALLATION_FOLDER_DIR}"
cd "${BUILD_FOLDER_DIR}"/

echo $PWD

cmake   \
    -G Ninja    \
    -S "${LLVM_9_DIR}/llvm"  \
    -B .    \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_INSTALL_PREFIX="${INSTALLATION_FOLDER_DIR}"  \
	-DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
	-DCMAKE_CXX_FLAGS="-include limits"	\
    -DLLVM_ENABLE_PROJECTS="llvm;clang;lld" \
    -DLLVM_INSTALL_UTILS=ON

cmake --build .

ninja install

# DCMAKE_CXX_FLAGS="-include limits"
# Need for building llvm-9 with g++ version >= 11.4.0 
