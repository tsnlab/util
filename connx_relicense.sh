#! /bin/bash

if [ $# -ne 3 ]; then
    echo "Usage $0 [destination dir] [LICENSE file for root dir] [license file for code]"
    exit 1
fi

DEST_DIR=$1
LICENSE_FILE=$2
LICENSE_HEADER=$3

echo -e "\e[32mCloning connx to ${DEST_DIR}\e[m"
git clone https://github.com/semihlab/connx ${DEST_DIR}

if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: Cannot clone connx repo\e[m"
    exit 1
fi

echo -e "\e[32mCreate TAG file\e[m"
pushd ${DEST_DIR}
git describe --tags --long > TAG
popd

if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: Cannot create TAG file\e[m"
    exit 1
fi

echo -e "\e[32mRemoving git related files\e[m"
find ${DEST_DIR} -name '.*' -exec rm -rf {} \;

echo -e "\e[32mRemove unnecessary file: TODO.md\e[m"
rm ${DEST_DIR}/TODO.md

if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: Cannot remove TODO.md file\e[m"
    exit 1
fi

echo -e "\e[32mReplace LICENSE: ${LICENSE_FILE} -> ${DEST_DIR}/LICENSE\e[m"
cp ${LICENSE_FILE} ${DEST_DIR}/LICENSE

if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: Cannot replace LICENSE file\e[m"
    exit 1
fi

echo -e "\e[32mRelicense source codes using license header file: ${LICENSE_HEADER}\e[m"
${DEST_DIR}/bin/relicense.py ${DEST_DIR} ${LICENSE_HEADER}

if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: Cannot relicense source code\e[m"
    exit 1
fi

echo -e "\e[32mCheck onnx test\e[m"
pushd ${DEST_DIR}/ports/linux
mkdir build
cd build
cmake .. -G Ninja

if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: cmake failed\e[m"
    popd
    exit 1
fi

ninja

if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: Build failed\e[m"
    popd
    exit 1
fi

python3 -m venv venv
source venv/bin/activate
pip install numpy

ninja onnx

if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: ONNX test failed\e[m"
    exit 1
fi

deactivate

cd ..
rm -rf build

popd

echo -e "\e[33mPlease remove unnecessary port ${DEST_DIR}/ports\e[m"
ls ${DEST_DIR}/ports

echo -e "\e[33mPlease remove unnecessary opset ${DEST_DIR}/src/opset\e[m"
ls ${DEST_DIR}/src/opset
