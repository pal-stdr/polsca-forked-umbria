user=$(if $(shell id -u),$(shell id -u),9001)
group=$(if $(shell id -g),$(shell id -g),1000)
phism=/workspace

# Changed for umbria
# vhls=/tools/Xilinx/2020.2
vhls=/opt/Xilinx/2022.2
th=1
# th=20

# example=2mm




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

UMBRIA_CPU_FLOW_RELATIVE_TMP_DIR=./tmp-umbria/umbria-cpu-flow

clean-umbria-cpu:
	rm -rf $(UMBRIA_CPU_FLOW_RELATIVE_TMP_DIR)




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

UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR=$(UMBRIA_CPU_FLOW_RELATIVE_TMP_DIR)/polybench
UMBRIA_POLYBENCH_PYTHON_SCRIPT=scripts/umbria-scripts/umbria-polybench-cpu-flow.py
POLYBENCH_SRC_DIR=./example/polybench
POLYBENCH_DATASET=SMALL
POLYBENCH_EXAMPLE=2mm
POLYBENCH_KERNELS=2mm
EXCLUDE_POLYBENCH_KERNELS=symm doitgen fdtd-2d jacobi-2d nussinov


# With Polymer


verify-one-polybench-kernel-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -p --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/verify-one-polybench-kernel-with-polymer --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report


verify-polybench-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) -p --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/verify-polybench-kernels-with-polymer --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)



run-one-polybench-kernel-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -p --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/run-one-polybench-kernel-with-polymer --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --run-bin-on-cpu --dump-csv-report


run-polybench-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) -p --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/run-polybench-kernels-with-polymer --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --run-bin-on-cpu --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)



compile-one-polybench-kernel-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -p --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/compile-one-polybench-kernel-with-polymer --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin


compile-polybench-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) -p --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/compile-polybench-kernels-with-polymer --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)



transform-one-polybench-kernel-with-polymer-example-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -p --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-one-polybench-kernel-with-polymer --only-kernel-transformation --excl $(EXCLUDE_POLYBENCH_KERNELS)


transform-polybench-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) -p --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-polybench-kernels-with-polymer --only-kernel-transformation --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)





# With Polymer + Scalehls


transform-one-polybench-kernel-with-polymer-scalehls-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -p --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-one-polybench-kernel-with-polymer-scalehls --only-kernel-transformation --enable-scalehls


transform-polybench-kernels-with-polymer-scalehls-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) -p --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-polybench-kernels-with-polymer-scalehls --only-kernel-transformation --enable-scalehls --dump-csv-report





# Without Polymer


verify-one-polybench-kernel-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/verify-one-polybench-kernel --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001


verify-polybench-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/verify-polybench-kernels --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)



run-one-polybench-kernel-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/run-one-polybench-kernel --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --run-bin-on-cpu


run-polybench-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/run-polybench-kernels --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --run-bin-on-cpu --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)



compile-one-polybench-kernel-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/compile-one-polybench-kernel --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin


compile-polybench-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/compile-polybench-kernels --dataset=$(POLYBENCH_DATASET) --clang-no-opt-bin --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)



transform-one-polybench-kernel-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-one-polybench-kernel --dataset=$(POLYBENCH_DATASET) --only-kernel-transformation --dump-csv-report


transform-polybench-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-polybench-kernels --dataset=$(POLYBENCH_DATASET) --only-kernel-transformation --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)





# Without Polymer, but with Scalehls


transform-one-polybench-kernel-with-scalehls-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) --source-dir $(POLYBENCH_SRC_DIR) -e $(POLYBENCH_EXAMPLE) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-one-polybench-kernel-with-scalehls --only-kernel-transformation --enable-scalehls --dump-csv-report


transform-polybench-kernels-with-scalehls-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_POLYBENCH_PYTHON_SCRIPT) -j $(th) --source-dir $(POLYBENCH_SRC_DIR) --work-dir $(UMBRIA_POLYBENCH_CPU_FLOW_RELATIVE_TMP_DIR)/transform-polybench-kernels-with-scalehls --only-kernel-transformation --enable-scalehls --dump-csv-report --excl $(EXCLUDE_POLYBENCH_KERNELS)






# --------------------- UMBRIA POLYBENCH BRAIN HSI CPU FLOW ---------------------


UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR=$(UMBRIA_CPU_FLOW_RELATIVE_TMP_DIR)/brain-hsi
UMBRIA_BRAIN_HSI_PYTHON_SCRIPT=scripts/umbria-scripts/umbria-polybench-brain-hsi-cpu-flow.py
BRAIN_HSI_KERNELS_SRC_DIR=./example/PolyBenchC-4.2.1-brain-HSI-without-path
UMBRIA_BRAIN_HSI_EXAMPLE=calibration
UMBRIA_BRAIN_HSI_KERNELS=calibration spectral_correction normalization svm_score probability_estimate gen_rgb_color_matrix brain_hsi
EXCLUDE_UMBRIA_BRAIN_HSI_KERNELS=brain_hsi



# With Polymer


verify-one-brain-hsi-kernel-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/verify-one-brain-hsi-kernels-with-polymer --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report


verify-brain-hsi-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/verify-brain-hsi-kernels-with-polymer --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report --excl $(EXCLUDE_UMBRIA_BRAIN_HSI_KERNELS)



run-one-brain-hsi-kernel-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/run-one-brain-hsi-kernel-with-polymer --clang-no-opt-bin --run-bin-on-cpu --dump-csv-report


run-brain-hsi-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/run-brain-hsi-kernels-with-polymer --clang-no-opt-bin --run-bin-on-cpu --dump-csv-report --excl $(EXCLUDE_UMBRIA_BRAIN_HSI_KERNELS)



compile-one-brain-hsi-kernel-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/compile-one-brain-hsi-kernel-with-polymer --clang-no-opt-bin


compile-brain-hsi-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/compile-brain-hsi-kernels-with-polymer --clang-no-opt-bin --dump-csv-report --excl $(EXCLUDE_UMBRIA_BRAIN_HSI_KERNELS)



transform-one-brain-hsi-kernel-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-one-brain-hsi-kernel-with-polymer --only-kernel-transformation --dump-csv-report


transform-brain-hsi-kernels-with-polymer-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-brain-hsi-kernels-with-polymer --only-kernel-transformation --dump-csv-report





# With Polymer + Scalehls


transform-one-brain-hsi-kernel-with-polymer-scalehls-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-one-brain-hsi-kernel-with-polymer-scalehls --only-kernel-transformation --enable-scalehls


transform-brain-hsi-kernels-with-polymer-scalehls-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) -p --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-brain-hsi-kernels-with-polymer-scalehls --only-kernel-transformation --enable-scalehls --dump-csv-report




# Without Polymer

verify-one-brain-hsi-kernel-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/verify-one-brain-hsi-kernel --dump-test-data-cpu --clang-no-opt-bin --sanity-check --verify-benchmark-result --error-threshold 0.00001


verify-brain-hsi-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/verify-brain-hsi-kernels --dump-test-data-cpu --clang-no-opt-bin --verify-benchmark-result --error-threshold 0.00001 --dump-csv-report --excl $(EXCLUDE_UMBRIA_BRAIN_HSI_KERNELS)


run-one-brain-hsi-kernel-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/run-one-brain-hsi-kernel --clang-no-opt-bin --run-bin-on-cpu --dump-csv-report


run-brain-hsi-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/run-brain-hsi-kernels --clang-no-opt-bin --run-bin-on-cpu --dump-csv-report --excl $(EXCLUDE_UMBRIA_BRAIN_HSI_KERNELS)



transform-one-brain-hsi-kernel-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-one-brain-hsi-kernel --only-kernel-transformation --dump-csv-report


transform-brain-hsi-kernels-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-brain-hsi-kernels --only-kernel-transformation --dump-csv-report




# Without Polymer, but with Scalehls


transform-one-brain-hsi-kernel-with-scalehls-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) -e $(UMBRIA_BRAIN_HSI_EXAMPLE) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-one-brain-hsi-kernel-with-scalehls --only-kernel-transformation --enable-scalehls --dump-csv-report


transform-brain-hsi-kernels-with-scalehls-umbria-cpu-flow:
	PYTHONPATH=$(shell pwd) python3 $(UMBRIA_BRAIN_HSI_PYTHON_SCRIPT) -j $(th) --source-dir $(BRAIN_HSI_KERNELS_SRC_DIR) --examples $(UMBRIA_BRAIN_HSI_KERNELS) --work-dir $(UMBRIA_BRAIN_HSI_CPU_FLOW_RELATIVE_TMP_DIR)/transform-brain-hsi-kernels-with-scalehls --only-kernel-transformation --enable-scalehls --dump-csv-report