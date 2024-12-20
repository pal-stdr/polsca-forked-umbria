user=$(if $(shell id -u),$(shell id -u),9001)
group=$(if $(shell id -g),$(shell id -g),1000)
phism=/workspace

# Changed for umbria
# vhls=/tools/Xilinx/2020.2
th=1
# example=2mm
vhls=/opt/Xilinx/2022.2
# th=20
# example=2mm
# example=covariance
# example=symm
# example=deriche
# example=jacobi-2d
example=calibration



# Build Phism
build-docker: test-docker
	docker run -it -v $(shell pwd):/workspace -v $(vhls):$(vhls) phism8:latest /bin/bash \
	-c "make build-phism"
	echo "Phism has been installed successfully!"

# Build docker container
test-docker:
	(cd Docker; docker build --build-arg UID=$(user) --build-arg GID=$(group) --build-arg VHLS_PATH=$(vhls) . --tag phism8)

# Enter docker container
shell:
	docker run -it -v $(shell pwd):/workspace -v $(vhls):$(vhls) phism8:latest /bin/bash

test-example:
	python3 scripts/pb-flow.py ./example/polybench -e $(example) --work-dir ./tmp/phism/pb-flow.tmp --cosim

# Evaluate polybench (baseline) - need to be used in environment
test-polybench:
	python3 scripts/pb-flow.py -c -j $(th) example/polybench

# Evaluate polybench (polymer) - need to be used in environment
test-polybench-polymer:
	python3 scripts/pb-flow.py -c -p -j $(th) example/polybench

# Build LLVM and Phism - temporary fix for missing mlir-clang
build-phism:
	./scripts/build-llvm.sh
	./scripts/build-polygeist.sh
	(cd ./polygeist/build; make mlir-clang)
	./scripts/build-polymer.sh
	./scripts/build-phism.sh

# Sync and update submodules
sync:
	git submodule sync
	git submodule update --init --recursive

# clean: clean-phism
# 	rm -rf $(phism)/llvm/build

# clean-phism:
# 	rm -rf $(phism)/build




# ===================== UMBRIA =====================

# The absolute path to the directory of this script. (not used)
PROJECT_ROOT_ABS_DIR=$(shell cd "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))" && pwd)

UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR=./tmp-umbria/umbria-cpu-flow

clean-umbria-cpu:
	rm -rf $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)




# # --------------------- WITH XILINX HLS COSIM FLOW ---------------------

# test-one-example-with-umbria-with-xilinx-hls-cosim:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-flow-with-xilinx-cosim.py -j $(th) ./example/polybench -e $(example) --work-dir ./tmp-umbria/cosim/single-polygeist-example/umbria-pb-flow.tmp --cosim


# test-one-polymer-example-with-umbria-with-xilinx-hls-cosim:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-flow-with-xilinx-cosim.py -p -j $(th) ./example/polybench -e $(example) --work-dir ./tmp-umbria/cosim/single-polymer-example/umbria-pb-flow.tmp --cosim


# # Test array partition
# test-one-polymer-example-ap-active-with-umbria-with-xilinx-hls-cosim:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-flow-with-xilinx-cosim.py -p --ap -j $(th) ./example/polybench -e $(example) --work-dir ./tmp-umbria/cosim/single-polymer-example/umbria-pb-flow.tmp --cosim




# # Evaluate polybench (baseline) - need to be used in environment
# test-umbria-polybench-polygeist-with-xilinx-hls-cosim:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-flow-with-xilinx-cosim.py -c -j $(th) example/polybench --work-dir ./tmp-umbria/cosim/polybench-with-polygeist/umbria-pb-flow.tmp --cosim


# # Evaluate polybench (polymer) - need to be used in environment
# test-umbria-polybench-polymer-with-xilinx-hls-cosim:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-flow-with-xilinx-cosim.py -c -p -j $(th) example/polybench --work-dir ./tmp-umbria/cosim/polybench-with-polymer/umbria-pb-flow.tmp --cosim






# --------------------- WITH EMIT C HLS ---------------------


# test-one-example-emit-c-hls:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-emit-c-hls.py -j $(th) ./example/polybench -e $(example) --work-dir ./tmp-umbria/emit-c-hls/single-polygeist-example/umbria-pb-flow.tmp --cosim


# test-one-polymer-example-emit-c-hls:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-emit-c-hls.py -p -j $(th) ./example/polybench -e $(example) --work-dir ./tmp-umbria/emit-c-hls/single-polymer-example/umbria-pb-flow.tmp --cosim


# # Test array partition (ap = array partition)
# test-one-polymer-example-ap-active-emit-c-hls:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-emit-c-hls.py -p --ap -j $(th) ./example/polybench -e $(example) --work-dir ./tmp-umbria/emit-c-hls/single-polymer-example/umbria-pb-flow.tmp --cosim




# # Evaluate polybench (baseline) - need to be used in environment
# test-umbria-polybench-polygeist-emit-c-hls:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-emit-c-hls.py -c -j $(th) example/polybench --work-dir ./tmp-umbria/emit-c-hls/polybench-with-polygeist/umbria-pb-flow.tmp --cosim


# # Evaluate polybench (polymer) - need to be used in environment
# test-umbria-polybench-polymer-emit-c-hls:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-emit-c-hls.py -c -p -j $(th) example/polybench --work-dir ./tmp-umbria/emit-c-hls/polybench-with-polymer/umbria-pb-flow.tmp --cosim










# --------------------- UMBRIA POLYBENCH CPU FLOW ---------------------

# With Polymer


# verify-one-polybench-kernel-with-polymer-example-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -p --source-dir ./example/polybench -e $(example) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/verify-single-polymer-example --dump-test-data-cpu --loop-transforms --clang-no-opt-bin --sanity-check --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report --dataset=SMALL


# test-one-polybench-kernel-with-polymer-example-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -p --source-dir ./example/polybench -e $(example) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/single-polymer-example --loop-transforms --clang-no-opt-bin --run-bin-on-cpu --dataset=SMALL --dump-csv-report


# verify-polybench-kernels-with-polymer-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -j $(th) -p --source-dir ./example/polybench --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/verify-polybench-kernels-with-polymer --dump-test-data-cpu --loop-transforms --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report --dataset=SMALL --excl symm doitgen fdtd-2d


# test-polybench-kernels-with-polymer-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -j $(th) -p --source-dir ./example/polybench --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/polybench-kernels-with-polymer --loop-transforms --clang-no-opt-bin --run-bin-on-cpu --dataset=SMALL --dump-csv-report --excl symm doitgen fdtd-2d nussinov



# transform-polybench-kernels-with-polymer-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -j $(th) -p --source-dir ./example/polybench --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-polybench-kernels-with-polymer --only-kernel-transformation --loop-transforms --dump-csv-report --excl symm doitgen fdtd-2d


# transform-one-polybench-kernel-with-polymer-example-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -j $(th) -p --source-dir ./example/polybench -e $(example) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-single-polybench-kernel-with-polymer --only-kernel-transformation --loop-transforms --excl symm doitgen fdtd-2d


# Without Polymer

# verify-one-polybench-example-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py --source-dir ./example/polybench -e $(example) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/verify-single-polybench-example --dump-test-data-cpu --loop-transforms --clang-no-opt-bin --sanity-check --verify-benchmark-result --error-threshold 0.00001 --dataset=SMALL


# test-one-polybench-example-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py --source-dir ./example/polybench -e $(example) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/single-polybench-example --loop-transforms --clang-no-opt-bin --run-bin-on-cpu --dataset=SMALL


# verify-polybench-kernels-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -j $(th) --source-dir ./example/polybench --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/verify-polybench-kernels-example --dump-test-data-cpu --loop-transforms --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dataset=SMALL --dump-csv-report --excl symm doitgen fdtd-2d


# test-polybench-kernels-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -j $(th) --source-dir ./example/polybench --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/polybench-example --loop-transforms --clang-no-opt-bin --run-bin-on-cpu --dataset=LARGE --dump-csv-report --excl symm doitgen fdtd-2d jacobi-2d nussinov



# transform-polybench-kernels-umbria-cpu-flow:
# 	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -j $(th) --source-dir ./example/polybench --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-kernel-polybench-example --only-kernel-transformation --loop-transforms --dump-csv-report --excl symm doitgen fdtd-2d





# --------------------- UMBRIA POLYBENCH BRAIN HSI CPU FLOW ---------------------


UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR=$(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/brain-hsi
UMBRIA_POLYBENCH_HSI_KERNELS=calibration spectral_correction normalization svm_score probability_estimate gen_rgb_color_matrix



# With Polymer


verify-one-brain-hsi-kernel-with-polymer-example-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -p --source-dir ./example/PolyBenchC-4.2.1-brain-HSI -e $(example) --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/verify-single-polymer-example --dump-test-data-cpu --loop-transforms --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report


test-one-brain-hsi-kernel-with-polymer-example-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -p --source-dir ./example/PolyBenchC-4.2.1-brain-HSI -e $(example) --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/single-polymer-example --loop-transforms --clang-no-opt-bin --run-bin-on-cpu --dataset=SMALL --dump-csv-report


verify-polybench-brain-hsi-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -j $(th) -p --source-dir ./example/PolyBenchC-4.2.1-brain-HSI --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/verify-polybench-kernels-with-polymer --dump-test-data-cpu --loop-transforms --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report --dataset=SMALL --excl symm doitgen fdtd-2d


test-polybench-brain-hsi-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -j $(th) -p --source-dir ./example/PolyBenchC-4.2.1-brain-HSI --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/polybench-kernels-with-polymer --loop-transforms --clang-no-opt-bin --run-bin-on-cpu --dataset=SMALL --dump-csv-report --excl symm doitgen fdtd-2d nussinov



transform-hsi-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -j $(th) -p --source-dir ./example/PolyBenchC-4.2.1-brain-HSI --examples $(UMBRIA_POLYBENCH_HSI_KERNELS) --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-polybench-kernels-with-polymer --only-kernel-transformation --loop-transforms --dump-csv-report --excl symm doitgen fdtd-2d


transform-one-hsi-kernel-with-polymer-example-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -j $(th) -p --source-dir ./example/PolyBenchC-4.2.1-brain-HSI -e $(example) --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-single-hsi-kernel-with-polymer --only-kernel-transformation --loop-transforms --excl symm doitgen fdtd-2d


# Without Polymer

verify-one-polybench-brain-hsi-example-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py --source-dir ./example/PolyBenchC-4.2.1-brain-HSI -e $(example) --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/verify-single-polybench-example --dump-test-data-cpu --loop-transforms --clang-no-opt-bin --sanity-check --verify-benchmark-result --error-threshold 0.00001 --dataset=SMALL


test-one-polybench-brain-hsi-example-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py --source-dir ./example/PolyBenchC-4.2.1-brain-HSI -e $(example) --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/single-polybench-example --loop-transforms --clang-no-opt-bin --run-bin-on-cpu --dataset=SMALL


verify-polybench-brain-hsi-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -j $(th) --source-dir ./example/PolyBenchC-4.2.1-brain-HSI --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/verify-polybench-kernels-example --dump-test-data-cpu --loop-transforms --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dataset=SMALL --dump-csv-report --excl symm doitgen fdtd-2d


test-polybench-brain-hsi-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -j $(th) --source-dir ./example/PolyBenchC-4.2.1-brain-HSI --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/polybench-example --loop-transforms --clang-no-opt-bin --run-bin-on-cpu --dataset=LARGE --dump-csv-report --excl symm doitgen fdtd-2d jacobi-2d nussinov



transform-polybench-brain-hsi-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py -j $(th) --source-dir ./example/PolyBenchC-4.2.1-brain-HSI --work-dir $(UMBRIA_POLYBENCH_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-kernel-polybench-example --only-kernel-transformation --loop-transforms --dump-csv-report --excl symm doitgen fdtd-2d








# --------------------- Trash test ---------------------



# Test array partition (ap = array partition)
test-one-polymer-example-ap-active-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -p --ap -j $(th) ./example/polybench -e $(example) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/single-polymer-example/umbria-pb-flow.tmp




# Evaluate polybench (baseline) - need to be used in environment
test-umbria-polybench-polygeist-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -c -j $(th) example/polybench --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/polybench-with-polygeist/umbria-pb-flow.tmp


# Evaluate polybench (polymer) - need to be used in environment
test-umbria-polybench-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 scripts/umbria-scripts/umbria-polybench-cpu-flow.py -c -p -j $(th) example/polybench --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/polybench-with-polymer/umbria-pb-flow.tmp