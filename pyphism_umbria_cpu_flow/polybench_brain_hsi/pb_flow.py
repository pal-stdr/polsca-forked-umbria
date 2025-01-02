""" Utitity functions for polybench evaluation.  """

import datetime
import functools
import itertools
import logging
import os
import shutil
import subprocess
import traceback

# Unused (Called, but not under any use)
from yaml import dump, load
# Unused (Called, but not under any use)
from yaml import CLoader as Loader

from collections import namedtuple
from dataclasses import dataclass, field
from multiprocessing import Pool
from timeit import default_timer as timer
from typing import Any, Dict, List, Optional

import re


import pandas as pd


from pyphism_umbria_cpu_flow.polybench_brain_hsi.options import PhismRunnerOptions



POLYBENCH_DATASETS = ("MINI", "SMALL", "MEDIUM", "LARGE", "EXTRALARGE")
POLYBENCH_EXAMPLES = (
    "2mm",
    "3mm",
    "adi",
    "atax",
    "bicg",
    "cholesky",
    "correlation",  # Result verification fails from dataset=SMALL or greater. But works for dataset=MINI
    "covariance",  # Result verification fails from dataset=SMALL or greater. But works for dataset=MINI
    "deriche",  # Compile problem
    "doitgen",  # Result problem
    "durbin",
    "fdtd-2d",  # Result problem
    "floyd-warshall",
    "gemm",
    "gemver",
    "gesummv",
    "gramschmidt",
    "heat-3d",
    "jacobi-1d",
    "jacobi-2d",  # Result fails for polymer. But only polybench works
    "lu",
    "ludcmp",
    "mvt",
    "nussinov",  # Compile problem
    "seidel-2d",
    "symm",  # Result problem
    "syr2k",
    "syrk",
    "trisolv",
    "trmm",
)

# Will be used to check different error msgs and making decision
ERROR_DICTIONARY = {
    "EXECUTION_ERROR": {
        "ERR_PROFILE_LOG_MATCH_CASE": r"^Error.*\n(.*)",
        "ERROR_MSG_MATCH_CASES": [ # It will be checked from "dump_kernel_profile_logs_to_file()"
            r"double free or corruption \(!prev\)\nAborted \(core dumped\)",  # typically happens for verification error
            r"malloc\(\): corrupted top size\nAborted \(core dumped\)"       # typically happens for execution error
        ]
    },
    "VERIFICATION_ERROR": {
        "ERR_PROFILE_LOG_MATCH_CASE": r"^Result mismatched.*\n(.*)",
    }
}




RECORD_FIELDS = (
    "name",
    "type",
    "polymer",
    "time",
    "execution_err",
    "verification_err",
    "run_status",
)


Record = namedtuple("Record", RECORD_FIELDS)




@dataclass
class PbFlowOptions(PhismRunnerOptions):
    """An interface for the CLI options."""

    # CLooG options
    cloogf: int = -1
    cloogl: int = -1
    diamond_tiling: bool = False
    dataset: str = "MINI"
    cleanup: bool = False
    debug: bool = False
    work_dir: str = ""
    dry_run: bool = False
    examples: List[str] = POLYBENCH_EXAMPLES
    excl: List[str] = field(default_factory=list)
    split: str = "NO_SPLIT"  # other options: "SPLIT", "HEURISTIC"
    loop_transforms: bool = False
    coalescing: bool = False  # enable loop coalescing
    constant_args: bool = True
    improve_pipelining: bool = False
    max_span: int = -1
    tile_sizes: Optional[List[int]] = None
    array_partition: bool = False
    cosim: bool = False
    skip_vitis: bool = False
    skip_csim: bool = False  # Given cosim = True, you can still turn down csim.
    sanity_check: bool = False  # Run pb-flow in sanity check mode

    array_partition_v2: bool = False  # Use the newer array partition (TODO: migrate)

    def __post_init__(self):
        if self.array_partition_v2:
            self.array_partition = True
        if self.sanity_check:
            # Disable the Vitis steps.
            self.cosim = False
            self.skip_vitis = True
            self.skip_csim = True


def filter_init_args(args: Dict[str, Any]) -> Dict[str, Any]:
    opt = PbFlowOptions(source_dir="")
    return {k: v for k, v in args.items() if hasattr(opt, k)}


# ----------------------- Utility functions ------------------------------------


def get_timestamp():
    """Get the current timestamp."""
    return datetime.datetime.now().strftime("%Y%m%d-%H%M%S")


def get_project_root():
    """Get the root directory of the project."""
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))




# ----------------------- Data processing ---------------------------

# Umbria add
def get_regex_filtered_result_list(result_file: str):
    """
    Results are dumped in following format from the Polybench kernel.
    ==BEGIN DUMP_ARRAYS==
    begin dump: D
    27.95 26.28 28.44
    ....
    end   dump: D
    ==END   DUMP_ARRAYS==

    Objective: Is to collect all the numbers and return them as a list
    """


    # Read the content of the file
    with open(result_file, "r") as file:
        content = file.read()
    
    # Use regex to extract all numbers (integers and floats)
    # result_list = re.findall(r"\d+\.\d+|\d+", content)
    result_content = re.findall(r"[-+]?\d*\.\d+|\d+", content)

    # Convert to int if no decimal point, else float
    result_list = [int(num) if '.' not in num else float(num) for num in result_content]

    # # Print the first 5 numbers
    # print(result_list[:10])

    # # Print the last 10 numbers
    # print(result_list[-10:])

    return result_list




# ----------------------- Benchmark runners ---------------------------


def discover_examples(
    d: str, examples: Optional[List[str]] = None, excludes: Optional[List[str]] = None
) -> List[str]:
    """Find examples in the given directory."""
    if not examples:
        examples = POLYBENCH_EXAMPLES

    return sorted(
        [
            # os.path.abspath(root)  # Convert to absolute path
            root
            for root, _, _ in os.walk(d)
            if os.path.basename(root).lower() in examples
            and os.path.basename(root).lower() not in excludes
        ]
    )


def get_phism_env():
    """Get the Phism run-time environment."""
    root_dir = get_project_root()

    phism_env = os.environ.copy()
    # phism_env["PATH"] = ":".join(
    #     [
    #         os.path.join(root_dir, "polygeist", "llvm-project", "build", "bin"),
    #         os.path.join(root_dir, "polygeist", "build", "mlir-clang"),
    #         os.path.join(root_dir, "polymer", "build", "bin"),
    #         os.path.join(root_dir, "build", "bin"),
    #         phism_env["PATH"],
    #     ]
    # )
    # phism_env["LD_LIBRARY_PATH"] = "{}:{}:{}:{}".format(
    #     os.path.join(root_dir, "polygeist", "llvm-project", "build", "lib"),
    #     os.path.join(root_dir, "polymer", "build", "pluto", "lib"),
    #     os.path.join(root_dir, "build", "lib"),
    #     phism_env["LD_LIBRARY_PATH"],
    # )

    # Redefined by umbria
    phism_env["PATH"] = ":".join(
    [
        os.path.join(root_dir, "llvm-14-src-build-for-polygeist-polymer-polsca", "bin"),
        os.path.join(root_dir, "polygeist-build-for-polsca", "mlir-clang"),
        os.path.join(root_dir, "polymer-build-for-polsca", "bin"),
        os.path.join(root_dir, "polsca-build", "bin"),
        os.path.join(root_dir, "scalehls-build", "bin"),
        os.path.join(root_dir, "papi-7-1-0-t-installation", "bin"),
        phism_env["PATH"],
    ]
    )
    phism_env["LD_LIBRARY_PATH"] = "{}:{}:{}:{}:{}".format(
        os.path.join(root_dir, "llvm-14-src-build-for-polygeist-polymer-polsca", "lib"),
        os.path.join(root_dir, "polymer-build-for-polsca", "pluto", "lib"),
        os.path.join(root_dir, "polsca-build", "lib"),
        os.path.join(root_dir, "scalehls-build", "lib"),
        os.path.join(root_dir, "papi-7-1-0-t-installation", "lib"),

        phism_env["LD_LIBRARY_PATH"],
    )

    return phism_env


def get_top_func(src_file):
    """Get top function name.
    some kernel files like jacobi-1d.c has a kernel defined as "kernel-jacobi_1d"
        1. This function takes thte path of that file
        2. Then strip just the file name (e.g. "jacobi-1d")
        3. Replace the "-" with "_" and return name as "jacobi_1d"
    """
    return "kernel_{}".format(os.path.basename(os.path.dirname(src_file))).replace(
        "-", "_"
    )






# class PbFlow(PhismRunner):
class PbFlow():
    """Holds all the pb-flow functions.
    TODO: inherits this from PhismFlow.
    """

    def __init__(self, work_dir: str, options: PbFlowOptions):
        """Constructor. `work_dir` is the top of the polybench directory."""
        self.env = get_phism_env()
        self.root_dir = get_project_root()
        self.work_dir = work_dir

        # Added by Umbria
        self.llvm_dir = os.path.join(self.root_dir, "polygeist", "llvm")
        self.llvm_build_dir = os.path.join(self.root_dir, "llvm-14-src-build-for-polygeist-polymer-polsca")
        self.polygeist_build_dir = os.path.join(self.root_dir, "polygeist-build-for-polsca")
        self.polymer_build_dir = os.path.join(self.root_dir, "polymer-build-for-polsca")
        self.polsca_build_dir = os.path.join(self.root_dir, "polsca-build")
        self.scalehls_build_dir = os.path.join(self.root_dir, "scalehls-build")
        self.papi_installation_dir = os.path.join(self.root_dir, "papi-7-1-0-t-installation")



        self.cur_file = None
        self.c_source = None
        self.options = options

        self.status = 0
        self.errmsg = "No Error"
        
        # self.kernel_execution_time = 0.00 # Added by Umbria
        # self.verification_errmsg = "" # Added by Umbria
        self.is_kernel_execution_error_found: bool = False # Added by Umbria
        self.is_result_mismatch_error_found: bool = False # Added by Umbria

        # Logger
        self.logger = logging.getLogger("pb-flow")
        self.logger.setLevel(logging.DEBUG)

    # Unused
    def setup_cfg(self):
        """Find the corresponding configuration."""
        if not self.options.cfg:
            return
        with open(self.options.cfg, "r") as f:
            self.logger.info(f"Key is {self.options.key}")
            cfg = load(f, Loader)
            if self.options.key in cfg:
                # NOTE: make sure you specify the configuration with the right key name.
                if "options" not in cfg[self.options.key]:
                    return
                if not cfg[self.options.key]["options"]:
                    return

                for k, v in cfg[self.options.key]["options"].items():
                    self.logger.info(f"Setting {k}={v}")
                    self.options.__setattr__(k, v)

    def filter_disabled(self, args):
        # Filter out disabled passes.
        return [
            arg
            for arg in args
            if not self.options.disabled or arg not in self.options.disabled
        ]

    def run(self, src_file):
        """Run the whole pb-flow on the src_file (*.c)."""
        self.options.key = os.path.basename(src_file).split(".")[0]
        # self.setup_cfg()
        self.logger.info(self.options)
        self.cur_file = src_file
        self.c_source = src_file  # Will be useful in some later stages

        base_dir = os.path.dirname(src_file)

        # Setup logging
        log_file = os.path.join(base_dir, f"pb-flow.log")
        if os.path.isfile(log_file):
            os.remove(log_file)

        formatter = logging.Formatter(
            "[%(asctime)s][%(name)s][%(levelname)s] %(message)s"
        )
        fh = logging.FileHandler(log_file)
        fh.setFormatter(formatter)
        fh.setLevel(logging.DEBUG)
        self.logger.addHandler(fh)

        # The whole flow
        try:
            (
                self.generate_tile_sizes()  # Doesn't work
                # .dump_test_data()
                .dump_test_data_for_cpu()
                # .compile_c()
                .compile_c_for_cpu()   # If sanity_check==True, "-D POLYBENCH_TIME" deactivated
                .preprocess()
                .sanity_check()
                # .split_statements()   # It doesn't work
                # .extract_top_func() # It is doing scop_decomp inside
                .extract_top_func_for_cpu() # if self.options.only_kernel_transformation==True, it is going to remove main() from MLIR code
                .scop_decomposition_for_cpu() # if self.options.loop_transforms==True, it will be activated
                .sanity_check()
                # .polymer_opt()
                .polymer_opt_for_cpu()
                # .sanity_check()     # From here to onwards, sanity_check will fail because of polymer-opt. The dumped array numbers get multi-lined print
                .constant_args()    # transforms the mlir #map for affine dimension
                # .sanity_check()
                # .loop_transforms()
                .loop_transforms_for_cpu()
                # .sanity_check()
                # .array_partition()
                # .sanity_check(no_diff=True)
                .scop_stmt_inline()      # if self.options.loop_transforms==True, then this will be deactivated
                .transform_for_scalehls()   # Will only be used for "self.options.enable_scalehls==True"
                .scalehls_opt()
                .scalehls_translate_to_cpp()
                .mlir_opt_chain_for_cpu()
                # .lower_llvm()
                # .sanity_check()
                .translate_mlir_to_llvmir_for_cpu()
                .compile_bin_for_cpu()
                .run_bin_on_cpu()
                .verify_benchmark_result()
                .dump_kernel_profile_logs_to_file()
                # .sanity_check(no_diff=True)
            )
        except Exception as e:
            self.status = 1
            self.errmsg = e

            # If exception occurred, have to create a file named "transformation.error.log" in each kernel dir where the error occured
            # Later it will be used to trace the "transformation.error.log" to created log and report
            # If this file is found in any kernel dir, will be considered transformation error occurred
            base_dir = os.path.dirname(self.cur_file)

            # For Success case: cpu.profile.log
            transformation_error_log_file = os.path.join(base_dir, "transformation.error.log")

            # Ensure the file exists or create it empty if not
            open(transformation_error_log_file, "a").close()

            # Now dump error log the content in that file
            with open(transformation_error_log_file, "w") as error_file:
                error_file.write("".join(traceback.format_exc()))
                error_file.close()

            # Log stack
            self.logger.error(traceback.format_exc())


    def run_command(
        self, cmd: str = "", cmd_list: Optional[List[str]] = None, **kwargs
    ):
        """Single entry for running a command."""
        if "cwd" not in kwargs:
            kwargs.update({"cwd": os.path.dirname(self.cur_file)})

        if cmd_list:
            cmd_list = [cmd for cmd in cmd_list if cmd]
            cmd_ = " \\\n\t".join(cmd_list)
            self.logger.debug(f"{cmd_}")
            if self.options.dry_run:
                print(" ".join(cmd_list))
                return
            proc = subprocess.run(cmd_list, **kwargs)
        else:
            self.logger.debug(f"{cmd}")
            if self.options.dry_run:
                print(cmd)
                return
            proc = subprocess.run(cmd, **kwargs)

        cmd_str = cmd if cmd else " ".join(cmd_list)
        if proc.returncode != 0:
            raise RuntimeError(f"{cmd_str} failed.")

        return proc

    def get_program_abspath(self, program: str) -> str:
        """Get the absolute path of a program."""
        return str(
            subprocess.check_output(["which", program], env=self.env), "utf-8"
        ).strip()

    def get_golden_out_file(self) -> str:
        path = os.path.basename(self.cur_file)
        return os.path.join(
            os.path.dirname(self.cur_file), path.split(".")[0] + ".golden.out"
        )
    
    def get_kernel_name_with_path(self) -> str:
        path = os.path.basename(self.cur_file)
        return os.path.join(
            os.path.dirname(self.cur_file), path.split(".")[0]
        )
    
    def dump_test_data(self):
        """Compile and dump test data for sanity check."""
        if not self.options.sanity_check:
            return self

        out_file = self.get_golden_out_file()
        exe_file = self.cur_file.replace(".c", ".exe")
        self.run_command(
            cmd=" ".join(
                [
                    self.get_program_abspath("clang"),
                    "-D",
                    f"{self.options.dataset}_DATASET",
                    "-D",
                    "POLYBENCH_DUMP_ARRAYS",
                    "-I",
                    os.path.join(self.work_dir, "utilities"),
                    "-I",
                    # Changed by umbria
                    # os.path.join(
                    #     self.root_dir,
                    #     "polygeist",
                    #     "llvm-project",
                    #     "build",
                    #     "lib",
                    #     "clang",
                    #     "14.0.0",
                    #     "include",
                    # ),
                    os.path.join(
                        self.llvm_build_dir,
                        "lib",
                        "clang",
                        "14.0.0",
                        "include",
                    ),
                    "-lm",
                    self.cur_file,
                    os.path.join(self.work_dir, "utilities", "polybench.c"),
                    "-o",
                    exe_file,
                ]
            ),
            shell=True,
            env=self.env,
        )
        self.run_command(
            cmd=exe_file,
            stderr=open(out_file, "w"),
            env=self.env,
        )

        return self

    def generate_tile_sizes(self):
        """Generate the tile.sizes file that Pluto will read."""
        base_dir = os.path.dirname(self.cur_file)
        tile_file = os.path.join(base_dir, "tile.sizes")

        if not self.options.tile_sizes:
            if os.path.isfile(tile_file):
                os.remove(tile_file)
            return self

        with open(tile_file, "w") as f:
            for tile in self.options.tile_sizes:
                f.write(f"{tile}\n")

        return self

    def compile_c(self):
        """Compile C code to MLIR using mlir-clang."""
        src_file, self.cur_file = self.cur_file, self.cur_file.replace(".c", ".mlir")

        self.run_command(cmd=f'sed -i "s/static//g" {src_file}', shell=True)
        self.run_command(
            cmd=" ".join(
                [
                    self.get_program_abspath("mlir-clang"),
                    src_file,
                    "-memref-fullrank",
                    "-S",
                    "-O0",
                    "-D",
                    f"{self.options.dataset}_DATASET",
                    "-D",
                    "POLYBENCH_DUMP_ARRAYS",
                    "-I",
                    # Changed by umbria
                    # os.path.join(
                    #     self.root_dir,
                    #     "polygeist",
                    #     "llvm-project",
                    #     "build",
                    #     "lib",
                    #     "clang",
                    #     "14.0.0",
                    #     "include",
                    # ),
                    os.path.join(
                        self.llvm_build_dir,
                        "lib",
                        "clang",
                        "14.0.0",
                        "include",
                    ),
                    "-I",
                    os.path.join(self.work_dir, "utilities"),
                ]
            ),
            stdout=open(self.cur_file, "w"),
            shell=True,
            env=self.env,
        )
        return self

    def sanity_check(self, no_diff=False):
        """Sanity check the current file."""
        if not self.options.sanity_check:
            return self

        assert self.cur_file.endswith(".mlir"), "Should be an MLIR file."

        out_file = self.cur_file.replace(".mlir", ".out")
        self.run_command(
            cmd=" ".join(
                [
                    self.get_program_abspath("mlir-opt"),
                    "-convert-math-to-llvm",
                    "-lower-affine",
                    "-convert-scf-to-std",
                    "-convert-memref-to-llvm",
                    "-convert-std-to-llvm",
                    "-convert-arith-to-llvm",
                    "-reconcile-unrealized-casts",
                    self.cur_file,
                    "|",
                    self.get_program_abspath("mlir-translate"),
                    "-mlir-to-llvmir",
                    "|",
                    self.get_program_abspath("opt"),
                    "-O3",
                    "|",
                    self.get_program_abspath("lli"),
                ]
            ),
            shell=True,
            env=self.env,
            stderr=open(out_file, "w"),
        )

        if not no_diff:
            self.run_command(
                cmd_list=["diff", self.get_golden_out_file(), out_file],
                stdout=open(out_file.replace(".out", ".diff"), "w"),
            )

        return self
    
    def preprocess(self):
        """Do some preprocessing before extracting the top function."""
        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".pre.mlir"
        )
        self.run_command(
            cmd_list=[
                self.get_program_abspath("mlir-opt"),
                "-sccp" if not self.options.sanity_check else "",
                "-canonicalize",
                src_file,
            ],
            stderr=open(
                os.path.join(
                    os.path.dirname(self.cur_file),
                    self.cur_file.replace(".mlir", ".log"),
                ),
                "w",
            ),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )
        return self

    def split_statements(self):
        """Use Polymer to split statements."""
        if self.options.split == "NO_SPLIT":
            return self

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", f".{self.options.split.lower()}.mlir"
        )
        log_file = self.cur_file.replace(".mlir", ".log")

        self.run_command(
            cmd_list=[
                self.get_program_abspath("polymer-opt"),
                src_file,
                "-reg2mem",
                (
                    "-annotate-splittable"
                    if self.options.split == "SPLIT"
                    else "-annotate-heuristic"
                ),
                "-scop-stmt-split",
                "-canonicalize",
            ],
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self

    def extract_top_func(self):
        """Extract the top function and all the stuff it calls."""
        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".kern.mlir"
        )

        log_file = self.cur_file.replace(".mlir", ".log")
        args = [
            self.get_program_abspath("phism-opt"),
            src_file,
            f'-extract-top-func="name={get_top_func(src_file)} keepall={self.options.sanity_check}"',
            "-scop-decomp" if self.options.loop_transforms else "",
            "-debug",
        ]
        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )
        return self

    def polymer_opt(self):
        """Run polymer optimization."""
        if not self.options.polymer:
            return self

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".plmr.mlir"
        )
        log_file = self.cur_file.replace(".mlir", ".log")

        passes = [
            # f"-annotate-scop='functions={get_top_func(src_file)}'",
            "-fold-scf-if",
        ]
        if self.options.split == "NO_SPLIT":  # The split stmt has applied -reg2mem
            passes += [
                "-reg2mem",
            ]

        diamond_tiling = "diamond_tiling"
        if not self.options.diamond_tiling:
            diamond_tiling = ""
        passes += [
            "-extract-scop-stmt",
            f'-pluto-opt="cloogf={self.options.cloogf} cloogl={self.options.cloogl} {diamond_tiling}"',
            "-debug",
        ]

        self.run_command(
            cmd=" ".join(
                [
                    self.get_program_abspath("polymer-opt"),
                    src_file,
                ]
                + passes
            ),
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            shell=True,
            env=self.env,
        )

        return self

    def scop_stmt_inline(self):
        """Inline scop.stmt."""
        if self.options.loop_transforms:
            self.logger.debug(
                "Skipped scop.stmt inline since there're completed already in loop transforms."
            )
            return self

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".si.mlir"
        )
        log_file = self.cur_file.replace(".mlir", ".log")

        args = [
            self.get_program_abspath("phism-opt"),
            src_file,
            "-scop-stmt-inline",
            "-debug-only=loop-transforms",
        ]

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self

    def loop_transforms(self):
        """Run Phism loop transforms."""
        if not self.options.loop_transforms:
            return self

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".lt.mlir"
        )
        log_file = self.cur_file.replace(".mlir", ".log")

        args = [
            self.get_program_abspath("phism-opt"),
            src_file,
            # f'-loop-transforms="max-span={self.options.max_span}"',
            "-inline-scop-affine",
            "-affine-loop-unswitching",
            "-anno-point-loop",
            "-outline-proc-elem='no-ignored'",
            "-loop-redis-and-merge",
            "-scop-stmt-inline",
            # "-fold-if" if self.options.coalescing else "",
            # "-demote-bound-to-if" if self.options.coalescing else "",
            # "-fold-if",
            "-debug-only=loop-transforms",
        ]

        args = self.filter_disabled(args)

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self

    def array_partition(self):
        """Run Phism array partition transforms."""
        if not self.options.array_partition:
            return self
        if self.options.array_partition_v2:
            return self.phism_array_partition(
                split_non_affine=self.options.split_non_affine_v2,
                flatten=self.options.flatten_v2,
            )

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".ap.mlir"
        )
        log_file = self.cur_file.replace(".mlir", ".log")

        array_partition_file = os.path.join(
            os.path.dirname(self.cur_file), "array_partition.txt"
        )
        if os.path.isfile(array_partition_file):
            os.remove(array_partition_file)

        args = [
            self.get_program_abspath("phism-opt"),
            src_file,
            f'-simple-array-partition="dump-file=1 flatten=1 gen-main={self.options.sanity_check}"',
            "-canonicalize",
            "-debug-only=array-partition",
        ]

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self

    def constant_args(self):
        """Run Phism constant args."""
        if not self.options.constant_args:
            return self

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".ca.mlir"
        )
        log_file = self.cur_file.replace(".mlir", ".log")

        args = [
            self.get_program_abspath("phism-opt"),
            src_file,
            f'-replace-constant-arguments="name={get_top_func(src_file)}"',
            "-canonicalize",
        ]

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self

    def lower_scf(self):
        """Lower to SCF first."""
        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".scf.mlir"
        )

        self.run_command(
            cmd_list=[
                self.get_program_abspath("phism-opt"),
                src_file,
                "-lower-affine",
                "-loop-bound-hoisting" if self.options.coalescing else "",
                "-loop-coalescing" if self.options.coalescing else "",
            ],
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self

    def lower_llvm(self):
        """Lower from MLIR to LLVM."""
        src_file, self.cur_file = self.cur_file, self.cur_file.replace(".mlir", ".llvm")

        memref_option = (
            f"use-bare-ptr-memref-call-conv={0 if self.options.sanity_check else 1}"
        )
        convert_std_to_llvm = f'-convert-std-to-llvm="{memref_option}"'

        args = [
            self.get_program_abspath("mlir-opt"),
            src_file,
            "-convert-math-to-llvm",
            "-convert-scf-to-std",
            "-convert-memref-to-llvm",
            "-canonicalize",
            convert_std_to_llvm,
            "-convert-arith-to-llvm",
            "-reconcile-unrealized-casts",
            f"| {self.get_program_abspath('mlir-translate')} -mlir-to-llvmir",
        ]
        log_file = self.cur_file.replace(".llvm", ".log")

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stdout=open(self.cur_file, "w"),
            stderr=open(log_file, "w"),
            env=self.env,
        )

        return self




    def prep_polybench_c_macro_compile_flags(self):

        # if self.options.sanity_check is not True:
        #     return f"-D {self.options.dataset}_DATASET -D POLYBENCH_TIME -D POLYBENCH_PAPI -I {os.path.join(self.papi_installation_dir, 'include')} -L {os.path.join(self.papi_installation_dir, 'lib')} -lpapi"
        # else:
        #     return "-D MINI_DATASET -D POLYBENCH_DUMP_ARRAYS"

        # Base flags
        flags = [

        ]

        # If --verify-benchmark-result or --sanity-check is enabled
        if self.options.sanity_check or self.options.verify_benchmark_result or self.options.dump_test_data_cpu:
            # Turn off the papi
            self.options.enable_papi = False

            # Use MINI dataset by default, or SMALL if explicitly specified
            dataset = self.options.dataset if self.options.dataset in ("MINI", "SMALL", "MEDIUM", "LARGE", "EXTRALARGE") else "MINI"
            flags += [f"-D {dataset}_DATASET", "-D POLYBENCH_DUMP_ARRAYS"]
        else:
            flags += [f"-D {self.options.dataset}_DATASET"]
        
        # If papi is enabled (papi needs "-D POLYBENCH_TIME") (If sanity_check is enabled, it will automatically deactivate the papi)
        if self.options.enable_papi:
            flags += ["-D POLYBENCH_PAPI", "-D POLYBENCH_TIME", f"-I {os.path.join(self.papi_installation_dir, 'include')}", f"-L {os.path.join(self.papi_installation_dir, 'lib')}", "-lpapi"]


        # (sanity_check or verify_results or enable_papi) if any one of them is eanabled, donot add "-D POLYBENCH_TIME"
        if self.options.sanity_check or self.options.verify_benchmark_result or self.options.enable_papi:
            pass
        else:
            if "-D POLYBENCH_TIME" not in flags:
                flags += ["-D POLYBENCH_TIME"]
        

        
        # print("I am hit", flags)
        
        # If user wants only the kernel transformation (or the scalehls transformation flow), then we need to replace/remove all the previously added flags.
        # Because earlier flags are for executables
        if self.options.only_kernel_transformation or self.options.enable_scalehls:
            kernel_name = get_top_func(self.cur_file)
            flags = [f"--function={kernel_name}"]
            return " ".join(flags)

        

        # Join flags into a single string
        return " ".join(flags)


    def prep_clang_opt_flags_for_cpu(self):
        
        # Base flags
        flags = [

        ]

        if self.options.clang_opt_bin:
            flags += ["-O3"]
        else:
            flags += ["-O0", "-fno-unroll-loops", "-fno-vectorize", "-fno-slp-vectorize", "-fno-tree-vectorize"]

        # Join flags into a single string
        return " ".join(flags)


    def dump_test_data_for_cpu(self):
        """Compile and dump test data for result verification."""

        if self.options.only_kernel_transformation:
            return self


        if not self.options.dump_test_data_cpu and not self.options.verify_benchmark_result:
            return self


        # With papi activated, we will only do the performance test
        if self.options.enable_papi is True:
            return self


        out_file = self.get_golden_out_file()
        exe_file = self.cur_file.replace(".c", ".exe")
        self.run_command(
            cmd=" ".join(
                [
                    self.get_program_abspath("clang"),
                    # if self.options.sanity_check==True: then return "-D MINI_DATASET -D POLYBENCH_DUMP_ARRAYS", else "-D {self.options.dataset}_DATASET -D POLYBENCH_TIME"
                    self.prep_polybench_c_macro_compile_flags(),
                    "-I",
                    os.path.join(self.work_dir, "utilities"),
                    "-I",
                    os.path.join(
                        self.llvm_build_dir,
                        "lib",
                        "clang",
                        "14.0.0",
                        "include",
                    ),
                    self.prep_clang_opt_flags_for_cpu(),
                    # (
                    #     "-O3" if self.options.clang_opt_bin else 
                    #     "-O0 -fno-unroll-loops -fno-vectorize -fno-slp-vectorize -fno-tree-vectorize"  # add optimization flags
                    # ),
                    "-lm",
                    self.cur_file,
                    os.path.join(self.work_dir, "utilities", "polybench.c"),
                    "-o",
                    exe_file,
                ]
            ),
            shell=True,
            env=self.env,
        )
        self.run_command(
            cmd=exe_file,
            stderr=open(out_file, "w"),
            env=self.env,
        )

        return self


    def compile_c_for_cpu(self):
        """Compile C code to MLIR using mlir-clang. If the --sanity-check is true, then it will not be called. Because '-D POLYBENCH_TIME' will be activated for production compile to measure time. '-D POLYBENCH_TIME' make the sanity check to fail."""

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(".c", ".mlir")

        log_file = self.cur_file.replace(".mlir", ".log")

        # print(self.prep_polybench_c_macro_compile_flags())

        self.run_command(cmd=f'sed -i "s/static//g" {src_file}', shell=True)
        self.run_command(
            cmd=" ".join(
                [
                    self.get_program_abspath("mlir-clang"),
                    src_file,
                    "-memref-fullrank",
                    "-raise-scf-to-affine",
                    "-S",
                    "-O0",
                    # prepare flags (e.g. "-D {}_DATASET", "-D POLYBENCH_DUMP_ARRAYS", "-D POLYBENCH_PAPI", "-D POLYBENCH_TIME") based on condition "sanity_check", "verify_benchmark_result", "enable_papi"
                    self.prep_polybench_c_macro_compile_flags(),
                    "-I",
                    os.path.join(
                        self.llvm_build_dir,
                        "lib",
                        "clang",
                        "14.0.0",
                        "include",
                    ),
                    "-I",
                    os.path.join(self.work_dir, "utilities"),
                ]
            ),
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            shell=True,
            env=self.env,
        )
        return self


    def extract_top_func_for_cpu(self):
        """Extract the top function and all the stuff it calls. 'only_kernel_transformation' option is very important. Because if it is true, then "main()" is going to be removed from the MLIR code, and you cannot test with CPU flow."""

        # print("I am hit - for deriche")

        if self.options.only_kernel_transformation is True:
            keep_all = False
        elif self.options.enable_scalehls is True:
            keep_all = False
        else:
            keep_all = True


        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".ex-top-func.mlir"
        )

        log_file = self.cur_file.replace(".mlir", ".log")
        args = [
            self.get_program_abspath("phism-opt"),
            src_file,
            f'-extract-top-func="name={get_top_func(src_file)} keepall={keep_all}"',
            "-debug",
        ]
        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )
        return self


    def scop_decomposition_for_cpu(self):
        """Extract the top function and all the stuff it calls. 'keep_main_func_in_mlir' option is very important. Because if it is false, then main() is going to be removed from the MLIR code, and you cannot test with CPU flow."""

        if self.options.loop_transforms is not True:
            return self


        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".sd.mlir"
        )

        log_file = self.cur_file.replace(".mlir", ".log")
        args = [
            self.get_program_abspath("phism-opt"),
            src_file,
            "-scop-decomp",
            "-debug",
        ]
        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )
        return self


    def polymer_opt_for_cpu(self):
        """Run polymer optimization."""
        if not self.options.polymer:
            return self

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".plmr.mlir"
        )
        pluto_clast_file = self.cur_file.replace(".mlir", ".cloog")
        log_file = self.cur_file.replace(".mlir", ".log")

        passes = [
            f"-annotate-scop='functions={get_top_func(src_file)}'",
            "-fold-scf-if",
        ]
        if self.options.split == "NO_SPLIT":  # The split stmt has applied -reg2mem
            passes += [
                "-reg2mem",
            ]

        diamond_tiling = "diamond_tiling"
        if not self.options.diamond_tiling:
            diamond_tiling = ""
        passes += [
            "-extract-scop-stmt",
            f'-pluto-opt="dump-clast-after-pluto={pluto_clast_file} cloogf={self.options.cloogf} cloogl={self.options.cloogl} {diamond_tiling}"',
            "-debug",
        ]

        self.run_command(
            cmd=" ".join(
                [
                    self.get_program_abspath("polymer-opt"),
                    src_file,
                ]
                + passes
            ),
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            # stdout=open(pluto_clast_file, "w"),
            shell=True,
            env=self.env,
        )

        return self


    def loop_transforms_for_cpu(self):
        """Run Phism loop transforms."""
        if not self.options.loop_transforms:
            return self

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".lt.mlir"
        )
        log_file = self.cur_file.replace(".mlir", ".log")

        args = [
            self.get_program_abspath("phism-opt"),
            src_file,
            # f'-loop-transforms="max-span={self.options.max_span}"',
            "-inline-scop-affine",
            "-affine-loop-unswitching",
            "-anno-point-loop",
            # "-outline-proc-elem='no-ignored'",    # This will activate all separate "PE_"
            "-loop-redis-and-merge",
            "-scop-stmt-inline",
            # "-fold-if" if self.options.coalescing else "",
            # "-demote-bound-to-if" if self.options.coalescing else "",
            # "-fold-if",
            "-debug-only=loop-transforms",
        ]

        args = self.filter_disabled(args)

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self


    def transform_for_scalehls(self):

        """
        This is a prerequisite transformation only intended for scalehls.


        "func @kernel_kernel_name(..)" will be converted to "func.func @kernel_kernel_name(..)"
        But all the other parts will be intact.
        """

        if not self.options.enable_scalehls:
            return self
        

        assert self.cur_file.endswith(".mlir"), "Should be an mlir (i.e. *.mlir) file."

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".sclhls-add-func.mlir"
        )

        log_file = self.cur_file.replace(".mlir", ".log")

        
        # Read the mlir src file
        with open(src_file, "r") as file:
            mlir_code_file_content = file.read()
            file.close()
        

        # Regex pattern to match (for "func")
        pattern = r"^\s*func\b\s+(@\w+\()"  # Match 'func' at the start of a line followed by a function name


        # Replace 'func' with 'func.func'
        updated_mlir_code = re.sub(pattern, r"func.func \1", mlir_code_file_content, flags=re.MULTILINE)

        # print(updated_mlir_code)

        self.run_command(
            shell=True,
            text=True,   # Treat input/output as text
            cmd=f"tee {self.cur_file}",  # Replace with your desired command
            stdout=subprocess.PIPE,     # Optional: Capture `tee` output (not needed here)
            stderr=open(log_file, "w"),     # Optional: Capture errors
            input=updated_mlir_code,  # Pass file content directly, it will not work with stdin
            env=self.env
        )

        return self


    def scalehls_opt(self):

        """
        Scalehls optimization.
        """

        if not self.options.enable_scalehls:
            return self
        

        assert self.cur_file.endswith(".mlir"), "Should be an mlir (i.e. *.mlir) file."

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".sclhls-opt.mlir"
        )

        log_file = self.cur_file.replace(".mlir", ".log")

        args = [
            self.get_program_abspath("scalehls-opt"),
            src_file,
            # f'-loop-transforms="max-span={self.options.max_span}"',
            # f'-scalehls-dse-pipeline="top-func={get_top_func(src_file)} target-spec={samples/polybench/config.json}"',
            # "-fold-if" if self.options.coalescing else "",
            "-debug-only=scalehls",
        ]

        # args = self.filter_disabled(args)

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self


    def scalehls_translate_to_cpp(self):

        """
        Scalehls mlir to cpp translation.
        """

        if not self.options.enable_scalehls:
            return self
        

        assert self.cur_file.endswith(".mlir"), "Should be an mlir (i.e. *.mlir) file."

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".sclhls-trns.cpp"
        )

        log_file = self.cur_file.replace(".mlir", ".log")

        args = [
            self.get_program_abspath("scalehls-translate"),
            src_file,
            "-scalehls-emit-hlscpp",
            "-debug-only=scalehls",
        ]

        # args = self.filter_disabled(args)

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self




    def mlir_opt_chain_for_cpu(self):
        """mlir-opt CHAIN for CPU."""
        
        if self.options.only_kernel_transformation:
            return self
        

        assert self.cur_file.endswith(".mlir"), "Should be an MLIR file."

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".ml-opt.mlir"
        )
        log_file = self.cur_file.replace(".mlir", ".log")

        args = [
            self.get_program_abspath("mlir-opt"),
            src_file,
            "-convert-math-to-llvm",
            "-lower-affine",
            "-convert-scf-to-std",
            "-convert-memref-to-llvm",
            "-convert-std-to-llvm",
            "-convert-arith-to-llvm",
            "-reconcile-unrealized-casts"
        ]

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )

        return self


    def translate_mlir_to_llvmir_for_cpu(self):
        """mlir-opt CHAIN for CPU."""

        if self.options.only_kernel_transformation:
            return self


        assert self.cur_file.endswith(".mlir"), "Should be an MLIR file."

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".mlir", ".translate.mlir.ll"
        )
        log_file = self.cur_file.replace(".ll", ".log")

        args = [
            self.get_program_abspath("mlir-translate"),
            src_file,
            "--mlir-to-llvmir"
            "|",
            self.get_program_abspath("opt"),
            "-S",
            (
                "-O3" if self.options.clang_opt_bin else 
                "-O0 --disable-loop-unrolling"  # add optimization flags
            ),

        ]

        self.run_command(
            cmd=" ".join(args),
            shell=True,
            stderr=open(log_file, "w"),
            stdout=open(self.cur_file, "w"),
            env=self.env,
        )
        return self
    

    def compile_bin_for_cpu(self):
        """Compile bin for CPU."""

        if self.options.only_kernel_transformation:
            return self


        assert self.cur_file.endswith(".ll"), "Should be an llvm (i.e. *.ll) file."

        src_file, self.cur_file = self.cur_file, self.cur_file.replace(
            ".ll",
            (
                ".clang-opt.exe" if self.options.clang_opt_bin else 
                ".no-clang-opt.exe"
            ),
        )

        log_file = self.cur_file.replace(".ll", ".log")
        
        self.run_command(
            cmd=" ".join(
                [
                    self.get_program_abspath("clang"),
                    src_file,
                    os.path.join(
                        self.work_dir, "utilities", "polybench.c"
                    ),
                    # if self.options.sanity_check==True: then return "-D MINI_DATASET -D POLYBENCH_DUMP_ARRAYS", else "-D {self.options.dataset}_DATASET -D POLYBENCH_TIME"
                    self.prep_polybench_c_macro_compile_flags(),
                    "-I",
                    os.path.join(
                        self.llvm_build_dir,
                        "lib",
                        "clang",
                        "14.0.0",
                        "include",
                    ),
                    "-I",
                    os.path.join(self.work_dir, "utilities"),
                    self.prep_clang_opt_flags_for_cpu(),
                    # (
                    #     "-O3" if self.options.clang_opt_bin else 
                    #     "-O0 -fno-unroll-loops -fno-vectorize -fno-slp-vectorize -fno-tree-vectorize"  # add optimization flags
                    # ),
                    "-lm",
                    "-lc",
                    "-o",
                    self.cur_file
                ]
            ),
            stdout=open(self.cur_file, "w"),
            stderr=open(log_file, "w"),
            shell=True,
            env=self.env,
        )
        return self    
    

    def run_bin_on_cpu(self):
        """Run the 'cpu.exe' file. Assuming the 'cpu.exe' file has been generated/compiled.
        
        Some out files
        cpu-exe.stdout.log: If "-D POLYBENCH_TIME" is active (i.e. performance flow), then the time taken for execution will be dumped to this file. But for kernel result verification flow, this file will be left empty.
        cpu-exe.stderr.log: If "-D POLYBENCH_DUMP_ARRAY" is active (i.e. result verification flow), then the result will be dumped to this file for further result checking in next "verify_benchmark_result()" function in the chain. But for current setup, it has been found that, either for performance or result verification, it will be always populated with results.
        
        """

        if self.options.only_kernel_transformation:
            return self


        # If one of the following options are not set, then continue for the the transformation
        if not self.options.run_bin_on_cpu and not self.options.verify_benchmark_result:
            return self


        assert self.cur_file.endswith(".exe"), "Should be a cpu exe (i.e. *.exe) file."
        
        cpu_bin_file = self.cur_file
        base_dir = os.path.dirname(cpu_bin_file)
        
        log_file = os.path.join(base_dir, "cpu-exe.stdout.log")
        if os.path.isfile(log_file):
            os.remove(log_file)

        try:
            self.run_command(
                # cmd_list=["papi_command_line", "--debug", "PAPI_REF_CYC", "PAPI_TOT_CYC", f".{cpu_bin_file}"],
                cmd=" ".join(
                    [
                        # f"{cpu_bin_file}"
                        # "papi_command_line", "--debug", "PAPI_REF_CYC", "PAPI_TOT_CYC", f".{cpu_bin_file}"
                        (
                            f"papi_command_line --debug PAPI_REF_CYC PAPI_TOT_CYC .{cpu_bin_file}"
                            if self.options.enable_papi is True
                            else f"{cpu_bin_file}"
                        ),
                    ]
                ),
                stdout=open(log_file, "w"),
                stderr=open(os.path.join(base_dir, "cpu-exe.stderr.log"), "w"), # dumped arrays are out through stderr
                shell=True,
                env=self.env
            )

        # If any kernel execution get failed due to programming error, it should be caught as an exception. Niether next functions in the process chain won't be called.
        except Exception as e:
            # Important!! Setting it up will activate handle_kernel_execution_error() handler
            self.is_kernel_execution_error_found = True
            # # Log the error and continue
            # # print(f"Execution error: {e}. Stderr logged in {os.path.join(base_dir, 'cpu-exe.stderr.log')}")
            self.status = 1
            # self.errmsg = e

            # # Log stack
            # self.logger.error(traceback.format_exc())
        
        return self


    def verify_benchmark_result(self, no_diff=False):
        """Verify the result with *.golden.out.
        
        kernel.bla.bla.out: Run the kernel.cpu.exe again and dump the resutl to this file.
        kernel.bla.bla.diff: Compare the results in "kernel.bla.bla.out" vs "kernel.golden.out" and pipe/dump the comparison findings (i.e. "Result matched!!" or "Result mismatched!! Avg diff:..") to this file.

        """

        if self.options.only_kernel_transformation:
            return self
        
        # If there is an kernel execution error, there is no point in result checking
        if self.is_kernel_execution_error_found:
            return self


        if not self.options.verify_benchmark_result:
            return self
        

        
        

        assert self.cur_file.endswith(".exe"), f"Should be an exe file. {self.cur_file}"

        # Collect golden.out file
        cpu_bin_file_name = os.path.basename(self.cur_file)
        cpu_bin_file_dir = os.path.dirname(self.cur_file)
        cpu_bin_file_path = os.path.join(cpu_bin_file_dir, cpu_bin_file_name)
        golden_result_filename = cpu_bin_file_name.split(".")[0] + ".golden.out"
        golden_result_file_path = os.path.join(cpu_bin_file_dir, golden_result_filename)

        kernel_name = cpu_bin_file_name.split(".")[0]

        result_out_file = self.cur_file.replace(".exe", ".out")

        self.run_command(
            shell=True,
            cmd_list=[cpu_bin_file_path],
            # stdout=open(log_file, "w"),
            stderr=open(result_out_file, "w"),
            env=self.env,
            
        )

        # Collect the results as python list
        golden_result_list = get_regex_filtered_result_list(golden_result_file_path)
        bin_result_list = get_regex_filtered_result_list(result_out_file)

        # # Deliberately create error
        # bin_result_list.pop(5)


        # Prepare .diff file to be written
        result_diff_file = result_out_file.replace(".out", ".diff")


        # (Very important) Create the empty ".diff" file
        # Ensure the file exists or create it empty if not
        open(result_diff_file, "a").close()


        # Boolen to set & check
        # Difference between "is_mismatch_found" and "self.is_result_mismatch_error_found" is
        # "is_mismatch_found" is local to this function. And just used to make initial decision. Even if the initial mismatch is found, still later we have to check for expected tolerance.
        # "self.is_result_mismatch_error_found" is global and used for final decision making.
        is_mismatch_found = False

        # Prepare placeholders for summary and detailed differences
        summary = []
        details = []
        mismatched_indices = []
        differences = []

        # Compare 2 lists
        # Success
        if golden_result_list == bin_result_list:
            # Nothing to do
            # self.status = 0
            self.is_result_mismatch_error_found = False
            pass


        else:
            # Result mismatch found!!!
            # Now we have to check if that mismatch is in accepeted tolerance

            # Find mismatched indices and calculate differences
            for i, (golden, bin_res) in enumerate(zip(golden_result_list, bin_result_list)):
                if golden != bin_res:
                    is_mismatch_found = True
                    mismatched_indices.append(i)
                    differences.append(abs(golden - bin_res))
                    details.append(f"Index {i}: Golden -> {golden}, {kernel_name} -> {bin_res}")

            if is_mismatch_found:
                

                # Calculate the number of mismatched cells and average difference
                mismatched_count = len(mismatched_indices)
                avg_difference = sum(differences) / mismatched_count if mismatched_count > 0 else 0


                # If the size of the result arrays are different
                if len(golden_result_list) != len(bin_result_list):

                    self.is_result_mismatch_error_found = True

                    # Never set the error status here. because that will break the self.function() call chain and get out of the transformation + verification process
                    # self.status = 1

                    # Prepare the summary

                    # Common mismatch msg
                    summary.append(f"Result mismatched {kernel_name}")
                    
                    summary.append(f"Golden & {kernel_name} results have different lengths.")
                    summary.append(f"Golden list length: {len(golden_result_list)}")
                    summary.append(f"{kernel_name} list length: {len(bin_result_list)}")

                    # Extra elements in longer list
                    if len(golden_result_list) > len(bin_result_list):
                        summary.append("Extra elements in golden_result_list:")
                        summary.append(f"{golden_result_list[len(bin_result_list):]}")
                    else:
                        summary.append("Extra elements in bin_result_list:")
                        summary.append(f"{bin_result_list[len(golden_result_list):]}")

                
                # Create error status
                #TODO: Have to check for error defining thereshold and formula
                #TODO: Have define different status codes for success & error
                elif avg_difference > self.options.error_threshold:

                    self.is_result_mismatch_error_found = True

                    # Never set the error status here. because that will break the self.function() call chain and get out of the transformation + verification process
                    # self.status = 1
                    
                    # Prepare the summary
                    summary.append(f"Result mismatched!!")

                    summary.append(f"Avg diff: {avg_difference:.6f}")
                    summary.append(f"mismatched cells: {mismatched_count} among {len(golden_result_list)}")
                    summary.append(f"Differences found at the following indices:\n")

                    
                # # Write the summary first, then the details
                # with open(result_diff_file, "w") as diff:
                #     diff.write("\n".join(summary) + "\n")
                #     diff.write("Differences found at the following indices:\n")
                #     diff.write("\n".join(details) + "\n")
                #     diff.close()
            
            # No result verification error
            else:
                pass

            
        # # Open the result_diff_file in read mode to collect the contents in a variable
        # # Contents will be passed to the 
        # with open(result_diff_file, "r") as diff_file:
        #     file_content = diff_file.read()
        #     diff_file.close()


        # Mismatch error
        if self.is_result_mismatch_error_found:
            combined_result_mismatch_error_list = summary + details
            # Join the contents into a single string
            diff_file_content = "\n".join(combined_result_mismatch_error_list)

        # No Mismatch found
        else:
            summary.append(f"Result matched {kernel_name}!!")
            diff_file_content = "".join(summary)

        # print("diff_file_content", diff_file_content)

        self.run_command(
            shell=True,
            text=True,   # Treat input/output as text
            cmd=f"tee {result_diff_file}",  # Replace with your desired command
            stdout=subprocess.PIPE,     # Optional: Capture `tee` output (not needed here)
            stderr=subprocess.PIPE,     # Optional: Capture errors
            input=diff_file_content,  # Pass file content directly, it will not work with stdin
            env=self.env
        )

        return self


    def dump_kernel_profile_logs_to_file(self):
        """
        create 2 log files named "cpu.profile.log" & "cpu.profile.err.log"

        "cpu.profile.log":
        exec success case: execution time would be read from "cpu-exe.stdout.log", and written to "cpu.profile.log"
        exec error case: will be set to "0.00"
        self.options.verify_benchmark_result case: Will be set to "0.00". Because for such case, the "cpu-exe.stdout.log" is empty.

        "cpu.profile.err.log":
        Handle execution & verification error. There will be 2 types error cases. (determined by checking "cpu-exe.stderr.log" file).
        1. Only for cpu execution (compiled without "-D POLYBENCH_DUMP_ARRAY").
        2. Verfication after cpu execution (compiled with "-D POLYBENCH_DUMP_ARRAY").

        1st error case: You will see NO data. Because you didn't compiled with "-D POLYBENCH_DUMP_ARRAY"
        "
        malloc(): corrupted top size
        Aborted (core dumped)
        "

        2nd error case: You will see data. Because you compiled with "-D POLYBENCH_DUMP_ARRAY"
        "
        ==BEGIN DUMP_ARRAYS==
        begin dump: cov
        0.00 
        ....
        2671147320.85 
        end   dump: cov
        ==END   DUMP_ARRAYS==
        double free or corruption (!prev)
        Aborted (core dumped)
        "


        How this function works?

        self.is_kernel_execution_error_found: Read "cpu-exe.stderr.log" and match for pre-defined regex based (i.e. "ERROR_DICTIONARY["EXECUTION_ERROR"]["ERROR_MSG_MATCH_CASES"]") error case. If the regex match found, then dump the error log to "cpu.profile.err.log". And write "0.00" to "cpu.profile.log".

        self.is_result_mismatch_error_found: Read "kernel.bla.bla.diff", dump it to "cpu.profile.err.log". And write "0.00" to "cpu.profile.log".

        else: The performance execution flow is running. So collect the execution time from "cpu-exe.stdout.log" and dump it to "cpu.profile.log".

        """

        if self.options.only_kernel_transformation:
            return self


        # If one of the following options are not set, then continue for the the transformation
        if not self.options.run_bin_on_cpu and not self.options.verify_benchmark_result:
            return self


        # print("I am hit from dump kernel profile", get_top_func(self.cur_file))

        # VERY IMPORTANT
        # For error case & self.options.verify_benchmark_result enabled case, "0.00" will be written to "cpu.profile.log"
        # Default value to be written for execution error case
        value_to_write_in_the_file = 0.00

        # Format the number as a string with two decimal places
        default_formatted_zero_value = f"{value_to_write_in_the_file:.2f}"



        base_dir = os.path.dirname(self.cur_file)

        # For Success case: cpu.profile.log
        profile_log_file = os.path.join(base_dir, "cpu.profile.log")

        # Ensure the file exists or create it empty if not
        open(profile_log_file, "a").close()


        # For Error case: cpu.profile.err.log
        # Create a "cpu.profile.err.log". Other process might check this file to make decision.
        # Or those process can also check self.is_kernel_execution_error_found property to make decisions.
        # Both of the choices are open. Feel free to use any one
        profile_err_log_file = os.path.join(base_dir, "cpu.profile.err.log")

        # Ensure the "kern_name.cpu.profile.err.log" file exists or create it empty if not
        open(profile_err_log_file, "a").close()



        if self.is_kernel_execution_error_found:

            # Prepapre "cpu-exe.stderr.log" to read
            cpu_stderr_log_file = os.path.join(os.path.dirname(self.get_kernel_name_with_path()), "cpu-exe.stderr.log")

            # Read the "cpu-exe.stderr.log"
            with open(cpu_stderr_log_file, "r") as file:
                cpu_stderr_log_file_content = file.read()
                file.close()
            
            # Error message patterns to match
            # error_msg_patterns = [
            #     r"double free or corruption \(!prev\)\nAborted \(core dumped\)",  # for verification error
            #     r"malloc\(\): corrupted top size\nAborted \(core dumped\)"       # for execution error
            # ]
            error_msg_patterns = ERROR_DICTIONARY["EXECUTION_ERROR"]["ERROR_MSG_MATCH_CASES"]

            # Retrive matches
            matches = [match.group() for each_err_pattern in error_msg_patterns if (match := re.search(each_err_pattern, cpu_stderr_log_file_content))]

            # print("matches", matches)

            # Declare empty content arrar for the error log file
            error_content = []

            # Handle error
            if matches:
                error_content.append('Error:\n')
                error_content.extend(matches)

                # Write the error logs to the "cpu.profile.err.log" file
                with open(profile_err_log_file, "w") as error_file:
                    error_file.write("".join(error_content))
                    error_file.close()
        
            

            # For execution error, put "0.00" in the "cpu.profile.log" file
            self.run_command(
                shell=True,
                text=True,   # Treat input/output as text
                cmd=f"echo {default_formatted_zero_value} | tee {profile_log_file}",
                stdout=subprocess.PIPE,     # Optional: Capture `tee` output (not needed here)
                stderr=subprocess.PIPE,     # Optional: Capture errors
                env=self.env
            )

        elif self.is_result_mismatch_error_found:

            # Result mismatch has been already written to ".diff"  file.
            # Find that file to read the error log
            result_diff_file = self.cur_file.replace(".exe", ".diff")

            # print("result_diff_file", result_diff_file)

            # Read the ".diff"
            with open(result_diff_file, "r") as file:
                result_diff_file_content = file.read()
                file.close()
            

            # Dump the result mismatch logs to the "cpu.profile.err.log" file
            with open(profile_err_log_file, "w") as error_file:
                error_file.write(result_diff_file_content)
                error_file.close()


            # For result_mismatch_error, put "0.00" in the "cpu.profile.log" file
            self.run_command(
                shell=True,
                text=True,   # Treat input/output as text
                cmd=f"echo {default_formatted_zero_value} | tee {profile_log_file}",
                stdout=subprocess.PIPE,     # Optional: Capture `tee` output (not needed here)
                stderr=subprocess.PIPE,     # Optional: Capture errors
                env=self.env
            )

        else:
            # print("No std Error match found.")
            cpu_stdout_log_file = os.path.join(base_dir, "cpu-exe.stdout.log")

            if not os.path.isfile(cpu_stdout_log_file):
                raise Exception(cpu_stdout_log_file, "cpu-exe.stdout.log doesn't exist")
            
            
            # (IMPORTANT) Handle "self.options.verify_benchmark_result"
            # If the file "cpu-exe.stdout.log" is empty, set the value to "0.00"
            with open(cpu_stdout_log_file, "r") as file:
                cpu_stdout_log_file_content = file.read()
                file.close()

            # Empty Means only the result verification has been run
            if not cpu_stdout_log_file_content:
                # Write "0.00" to "cpu.profile.log"
                with open(profile_log_file, "w") as file:
                    file.write(default_formatted_zero_value)
                    file.close()

            else:

                self.run_command(
                    shell=True,
                    text=True,   # Treat input/output as text
                    cmd_list=[f"tee {profile_log_file} < {cpu_stdout_log_file}"],  # Redirects the content of cpu_stdout_log_file to tee.
                    stdout=subprocess.PIPE,     # Optional: Capture `tee` output (not needed here)
                    stderr=subprocess.PIPE,     # Optional: Capture errors
                    env=self.env
                )
        return self





# ----------------------- Data record fetching functions -----------------------



# This function should be always be used after checking transformation error
def is_kernel_execution_error_found(kernel_dir: str):
    
    is_execution_error_found = False

    # For Error case: cpu.profile.err.log
    kernel_profile_err_log_file = os.path.join(kernel_dir, "cpu.profile.err.log")

    # if the "cpu.profile.err.log" is not created, then transformation error occurred
    if not os.path.isfile(kernel_profile_err_log_file):
        return is_execution_error_found

    else:
        # Read the error logs to the "cpu.profile.err.log" file
        with open(kernel_profile_err_log_file, "r") as error_file:
            # Normalize, Ensure the input content has consistent newline characters (\n).
            kernel_profile_err_log_file_content = error_file.read().replace("\r\n", "\n").replace("\r", "\n")
            error_file.close()


        # !IMPORTANT, this has been set in "dump_kernel_profile_logs_to_file() function"
        # error_pattern_to_match = r"^Error.*\n(.*)"
        error_pattern_to_match = ERROR_DICTIONARY["EXECUTION_ERROR"]["ERR_PROFILE_LOG_MATCH_CASE"]

        error_match = re.search(error_pattern_to_match, kernel_profile_err_log_file_content, re.MULTILINE)

        if error_match:
            is_execution_error_found = True
            return is_execution_error_found
        else:
            return is_execution_error_found


def is_kernel_result_verification_error_found(kernel_dir: str):

    is_result_verification_error_found = False

    # For Error case: cpu.profile.err.log
    kernel_profile_err_log_file = os.path.join(kernel_dir, "cpu.profile.err.log")

    # if the "cpu.profile.err.log" is not created, then transformation error occurred
    if not os.path.isfile(kernel_profile_err_log_file):
        return is_result_verification_error_found

    else:
        # Read the error logs to the "cpu.profile.err.log" file
        with open(kernel_profile_err_log_file, "r") as error_file:
            # Normalize, Ensure the input content has consistent newline characters (\n).
            kernel_profile_err_log_file_content = error_file.read().replace("\r\n", "\n").replace("\r", "\n")
            error_file.close()


        # !IMPORTANT, this has been set in "dump_kernel_profile_logs_to_file() function"
        # error_pattern_to_match = r"^Error.*\n(.*)"
        error_pattern_to_match = ERROR_DICTIONARY["VERIFICATION_ERROR"]["ERR_PROFILE_LOG_MATCH_CASE"]

        error_match = re.search(error_pattern_to_match, kernel_profile_err_log_file_content, re.MULTILINE)

        if error_match:
            is_result_verification_error_found = True
            return is_result_verification_error_found
        else:
            return is_result_verification_error_found


# If compiler transformation error happens, "transformation.error.log" file doesn't get created in the first place.
def is_kernel_transformation_error(kernel_dir: str):

    # Default error state
    is_kern_transformation_error_found = False

    # First check if the error is thrown from the cpu execution
    # Because execution error is not transformation error
    if is_kernel_execution_error_found(kernel_dir):
        return is_kern_transformation_error_found



    # Check if there is an execution error
    # Find & set the path for "transformation.error.log"
    transformation_error_log_file = os.path.join(
        kernel_dir,
        "transformation.error.log"
    )


    # If compiler transformation error happens, this file doesn't get created in the first place
    if os.path.isfile(transformation_error_log_file):
        is_kern_transformation_error_found = True


    return is_kern_transformation_error_found


def fetch_kernel_execution_time(kernel_dir: str):
    """Fetch the execution time."""
    
    # For Success case: cpu.profile.log
    profile_log_file = os.path.join(kernel_dir, "cpu.profile.log")

    # Read the "cpu-exe.stderr.log"
    with open(profile_log_file, "r") as file:
        # default read will return '0.00\n'. So need to strip() special hidden characters
        profile_log_file_content = file.read().strip()
        file.close()


    if profile_log_file_content:
        return float(profile_log_file_content)
    else:
        return 0.00


def fetch_kernel_execution_error_status(kernel_dir: str):
    """
    Error status will be checked + collected from "cpu.profile.err.log":
    Check for Execution error status.
    """
    
    # For Error case: cpu.profile.err.log
    kernel_profile_err_log_file = os.path.join(kernel_dir, "cpu.profile.err.log")


    # if the "cpu.profile.err.log" is not created, then transformation error occurred
    if not os.path.isfile(kernel_profile_err_log_file):
        return "Transformation error occurred."


    # Read the "cpu-exe.stderr.log"
    with open(kernel_profile_err_log_file, "r") as error_file:
        # Normalize, Ensure the input content has consistent newline characters (\n).
        profile_err_log_file_content = error_file.read().replace("\r\n", "\n").replace("\r", "\n")
        error_file.close()

    # print("profile_err_log_file_content", repr(profile_err_log_file_content))


    # Primary search keyword is to make decision that there is an error
    # execution_error_keyword_pattern = r"^Error.*\n(.*)"
    execution_error_keyword_pattern = ERROR_DICTIONARY["EXECUTION_ERROR"]["ERR_PROFILE_LOG_MATCH_CASE"]

    
    # Check for the keyword "Error"
    # re.MULTILINE: This flag ensures that regex can match patterns line by line.
    if re.search(execution_error_keyword_pattern, profile_err_log_file_content, re.MULTILINE):

        extract_error_msg = re.search(execution_error_keyword_pattern, profile_err_log_file_content, re.MULTILINE).group(0).replace("\n", " ")  # Replace '\n' with space

        return extract_error_msg
    

    # No error case
    else:
        return "No Error"


def fetch_kernel_result_verification_error_status(kernel_dir: str):

    """
    Error status will be checked + collected from "cpu.profile.err.log":
    Check for result mismatch error:
    """
    
    # For Error case: cpu.profile.err.log
    kernel_profile_err_log_file = os.path.join(kernel_dir, "cpu.profile.err.log")


    # if the "cpu.profile.err.log" is not created, then transformation error occurred
    if not os.path.isfile(kernel_profile_err_log_file):
        return "Transformation error occurred."


    # Read the "cpu-exe.stderr.log"
    with open(kernel_profile_err_log_file, "r") as error_file:
        # Normalize, Ensure the input content has consistent newline characters (\n).
        profile_err_log_file_content = error_file.read().replace("\r\n", "\n").replace("\r", "\n")
        error_file.close()

    # print("profile_err_log_file_content", repr(profile_err_log_file_content))


    # Result mismatch search keyword is to make decision that there is result verification error
    # result_mismatch_keyword_pattern = r"^Result mismatched.*\n(.*)"
    result_mismatch_keyword_pattern = ERROR_DICTIONARY["VERIFICATION_ERROR"]["ERR_PROFILE_LOG_MATCH_CASE"]

    
    # Check for the keyword "Result mismatched"
    # re.MULTILINE: This flag ensures that regex can match patterns line by line.
    if re.search(result_mismatch_keyword_pattern, profile_err_log_file_content):

        # Extract mismatch msg
        extract_mismatch_error_msg = re.search(result_mismatch_keyword_pattern, profile_err_log_file_content, re.MULTILINE).group(0).replace("\n", " ")  # Replace '\n' with space

        return extract_mismatch_error_msg

    # No error case
    else:
        return "No Error"    



def pb_flow_process(relative_temp_kernel_dir: str, work_dir: str, options: PbFlowOptions):
    """Process a single example.

    relative_temp_kernel_dir (str): Relative path of temporary kernel dir where the transformations will be dumped (e.g. ./tmp-umbria/umbria-cpu-flow/single-polymer-example/umbria-pb-flow.tmp/linear-algebra/kernels/2mm)

    work_dir (str): Abs path of the root temp kernel dir. (e.g. /abs/path/to/polsca-forked-umbria/tmp-umbria/umbria-cpu-flow/single-polymer-example/umbria-pb-flow.tmp/linear-algebra/kernels/2mm)
    """
    # Make sure the example directory and the work directory are both absolute paths.
    # TODO: make it clear what is d.
    
    temp_kernel_abs_dir = os.path.abspath(relative_temp_kernel_dir)


    # Root Temporary folder where all the transformations are dumped (e.g. tmp-umbria/umbria-cpu-flow/single-polymer-example/umbria-pb-flow.tmp)
    work_dir = os.path.abspath(work_dir)


    flow = PbFlow(work_dir, options)
    src_file = os.path.join(temp_kernel_abs_dir, os.path.basename(temp_kernel_abs_dir) + ".c")

    # Run the whole process on the kernel *.c file (transformation + run)
    flow.run(src_file)

    
    
    # Check for different kind of error found
    # Always have to check this "only_kernel_transformation" first
    if options.only_kernel_transformation:
        if not options.dry_run:

            if is_kernel_transformation_error(temp_kernel_abs_dir):
                
                print(
                    '>>> Transformation Error occured for {:15s}  Status: {}  Error: "{}"'.format(
                        os.path.basename(temp_kernel_abs_dir), flow.status, flow.errmsg
                    )
                )
            else:
                # print("I am hit", is_kernel_transformation_error(temp_kernel_abs_dir))
                print(
                    '>>> Transformation Successfull for {:15s}  Status: {}  Error: "{}"'.format(
                        os.path.basename(temp_kernel_abs_dir), flow.status, flow.errmsg
                    )
                )

    elif options.run_bin_on_cpu or options.verify_benchmark_result or options.sanity_check:

        if not options.dry_run:

            if is_kernel_transformation_error(temp_kernel_abs_dir):
                    
                # print("I am hit", is_kernel_transformation_error(temp_kernel_abs_dir))
                print(
                    '>>> Transformation Error occured {:15s}  Status: {}  Error: "{}"'.format(
                        os.path.basename(temp_kernel_abs_dir), flow.status, flow.errmsg
                    )
                )

            elif is_kernel_execution_error_found(temp_kernel_abs_dir):

                print(
                    '>>> Execution error occured {:15s}  Status: {}  Error: "{}"'.format(
                        os.path.basename(temp_kernel_abs_dir), flow.status, fetch_kernel_execution_error_status(temp_kernel_abs_dir)
                    )
                )
            
            elif is_kernel_result_verification_error_found(temp_kernel_abs_dir):

                print(
                    '>>> Result verification error occured {:15s}  Status: {}  Error: "{}"'.format(
                        os.path.basename(temp_kernel_abs_dir), flow.status, fetch_kernel_result_verification_error_status(temp_kernel_abs_dir)
                    )
                )
            
            else:
                # Retrieve dir of the "kernel_name.cpu.profile.log"
                profile_log_file = os.path.join(
                    temp_kernel_abs_dir,
                    "cpu.profile.log"
                )

                # Read the "kernel_name.cpu.profile.log"
                with open(profile_log_file, "r") as file:
                    profile_log_content = file.read()
                    file.close()

                print(
                    '>>> Finished {:15s} elapsed: {:.6f} secs   Status: {}  Error: "{}"'.format(
                        os.path.basename(temp_kernel_abs_dir), float(profile_log_content), flow.status, flow.errmsg
                    )
                )

    # Just compile and do nothing else
    else:
        if not options.dry_run:
            if is_kernel_transformation_error(temp_kernel_abs_dir):   
                # print("I am hit", is_kernel_transformation_error(temp_kernel_abs_dir))
                print(
                    '>>> Transformation Error occured {:15s}  Status: {}  Error: "{}"'.format(
                        os.path.basename(temp_kernel_abs_dir), flow.status, flow.errmsg
                    )
                )
            else:
                print(
                    '>>> Finished {:15s} elapsed: {:.6f} secs   Status: {}  Error: "{}"'.format(
                        os.path.basename(temp_kernel_abs_dir), float(0.00), flow.status, flow.errmsg
                    )
                )
        


def process_pb_flow_result_dir(result_work_dir: str, options: PbFlowOptions):
    """Process the result directory from pb-flow runs."""
    records = []
    assert os.path.isdir(result_work_dir), f"{result_work_dir} doens't exist."

    final_kernel_relative_dir_list = discover_examples(
        result_work_dir,    # i.e. options.work_dir,
        examples=options.examples,
        excludes=options.excl
    )

    # print(final_kernel_relative_dir_list)

    # If performance run or verification of benchmark results, then use same format for log
    if options.run_bin_on_cpu or options.verify_benchmark_result:

        # Create records for each directory
        records = [
            Record (
                os.path.basename(each_kernel_dir),  # kernel name
                # "dummy-operation-name",
                # here is "operation_name" field
                (
                    "cpu-exe-opt" if options.run_bin_on_cpu and options.clang_opt_bin else
                    "cpu-exe-no-opt" if options.run_bin_on_cpu and not options.clang_opt_bin else
                    "verification" if options.verify_benchmark_result else 
                    "unknown"  # Optional fallback if none of the options are True
                ),
                "yes" if options.polymer else "no",
                0.00 if is_kernel_transformation_error(each_kernel_dir) else fetch_kernel_execution_time(each_kernel_dir),
                "yes" if is_kernel_execution_error_found(each_kernel_dir) else "no",
                (
                    "N/A" if options.run_bin_on_cpu else # For kernel performance execution, verification is not applicable
                    "yes" if is_kernel_result_verification_error_found(each_kernel_dir) else "no"
                ),
                

                (
                    "transformation error" if is_kernel_transformation_error(each_kernel_dir) else
                    fetch_kernel_execution_error_status(each_kernel_dir) if is_kernel_execution_error_found(each_kernel_dir) else
                    fetch_kernel_result_verification_error_status(each_kernel_dir) if is_kernel_result_verification_error_found(each_kernel_dir) else
                    "No Error"
                )
            )
            for each_kernel_dir in final_kernel_relative_dir_list
        ]
    
    # Only compilation flow
    elif not options.run_bin_on_cpu and not options.verify_benchmark_result and not options.only_kernel_transformation:
        # Create records for each directory
        records = [
            Record(
                os.path.basename(each_kernel_dir),  # kernel name
                "only-compilation",
                "yes" if options.polymer else "no",
                0.00,   # Default 0.00
                "N/A",
                "N/A",
                "Compilation Success" if not is_kernel_transformation_error(each_kernel_dir) else "Compilation Error"
            )
            for each_kernel_dir in final_kernel_relative_dir_list
        ]

    elif options.only_kernel_transformation:
        # Create records for each directory
        records = [
            Record(
                os.path.basename(each_kernel_dir),  # kernel name
                ( 
                    "mlir-transform" if options.only_kernel_transformation and not options.enable_scalehls else
                    "scalehls-transform" if options.only_kernel_transformation and options.enable_scalehls else
                    "unknown"  # Optional fallback if none of the options are True
                ),
                "yes" if options.polymer else "no",
                0.00,   # Default 0.00
                "N/A",
                "N/A",
                "Transformation Success" if not is_kernel_transformation_error(each_kernel_dir) else "Transformation Error"
            )
            for each_kernel_dir in final_kernel_relative_dir_list
        ]

    return records



# ----------------------- Panda Utilities -----------------------


def is_list_record(x):
    return isinstance(
        x,
        (
            Record,
        )
    )


def flatten_record(record):
    """Flatten a Record object into a list."""
    return list(
        itertools.chain(*[list(x) if is_list_record(x) else [x] for x in record])
    )


def to_pandas(records):
    """From processed records to pandas DataFrame."""
    # cols = list(itertools.chain(*[expand_field(field) for field in RECORD_FIELDS]))
    cols = list(itertools.chain([field for field in RECORD_FIELDS]))
    data = list([flatten_record(r) for r in records])
    data.sort(key=lambda x: x[0])

    # NOTE: dtype=object here prevents pandas converting integer to float.
    return pd.DataFrame(data=data, columns=cols, dtype=object)


def pb_flow_dump_report(options: PbFlowOptions):
    """Dump report to the work_dir."""
    df = to_pandas(process_pb_flow_result_dir(options.work_dir, options))
    print("\n")
    print(df)
    print("\n")


    df.to_csv(
        os.path.join(
            options.work_dir,
            f"pb-flow.report.{get_timestamp()}.csv"
        )
    )



# ----------------------- Core Pbflow Runner -----------------------


def pb_flow_runner(options: PbFlowOptions, dump_report: bool = True):
    """Run pb-flow with the provided arguments."""
    assert os.path.isdir(options.source_dir)

    # print("options.source_dir", options.source_dir)
    # print("options.work_dir", options.work_dir)

    if not options.examples:
        options.examples = POLYBENCH_EXAMPLES

    # Copy all the files from the source source_dir to a target temporary directory.
    if not options.work_dir:
        options.work_dir = os.path.join(
            get_project_root(), "tmp", "phism", "pb-flow.{}".format(get_timestamp())
        )
    if not os.path.exists(options.work_dir):
        shutil.copytree(options.source_dir, options.work_dir)

    print(
        ">>> Starting {} jobs (work_dir={}) ...".format(options.jobs, options.work_dir)
    )

    start = timer()
    with Pool(options.jobs) as p:
        # TODO: don't pass work_dir as an argument. Reuse it.
        p.map(
            functools.partial(
                pb_flow_process, work_dir=options.work_dir, options=options
            ),
            discover_examples(
                options.work_dir, examples=options.examples, excludes=options.excl
            ),
        )
    end = timer()
    print("Elapsed time: {:.6f} sec".format(end - start))

    # Will only dump report if Vitis has been run.
    if dump_report:
        print(">>> Dumping report ... ")
        pb_flow_dump_report(options)


# ------------------------------ Plotting -------------------------------
