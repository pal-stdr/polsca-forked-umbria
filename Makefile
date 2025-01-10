user=$(if $(shell id -u),$(shell id -u),9001)
group=$(if $(shell id -g),$(shell id -g),1000)
phism=/workspace

# Changed for umbria
# vhls=/tools/Xilinx/2020.2
vhls=/opt/Xilinx/2022.2
# th=1
th=1

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







UMBRIA_CPU_FLOW_RELATIVE_TMP_DIR=./tmp-umbria/umbria-cpu-flow

clean-umbria-cpu:
	rm -rf $(UMBRIA_CPU_FLOW_RELATIVE_TMP_DIR)




# --------------------- UMBRIA POLYBENCH CPU FLOW ---------------------

include makefile_polybench_polygeist_targets

include makefile_polybench_polly_llvm_targets






# --------------------- UMBRIA POLYBENCH BRAIN HSI CPU FLOW ---------------------

include makefile_brain_hsi_polygeist_targets

include makefile_brain_hsi_polly_llvm_targets
