from dataclasses import dataclass
from typing import List, Optional


@dataclass
class PhismRunnerOptions:
    """Phism runner options.

    TODO: separate the CLI part (for all files) and the class part (for one file).
    """

    # --- Local
    key: str = ""  # The key to the current example.
    source_file: str = ""  # input source file
    top_func: str = ""  # top function name
    incl_funcs: str = ""  # include functions for SCoP extraction
    disabled: Optional[List[str]] = None  # disabled passes

    # --- Global
    cfg: str = ""  # configuration file.
    polymer: bool = False  # run with polymer
    loop_transforms: bool = False  # Default, False, run phism loop transform
    array_partition: bool = False  # run phism array partition
    fold_if: bool = False  # run phism fold if
    skip_vitis: bool = False  # whether to skip the whole vitis flow
    cosim: bool = False  # whether to run cosim
    dry_run: bool = False  # only print out the commands to run
    sanity_check: bool = True  # run in sanity check mode
    source_dir: str = ""  # if specified, won't work with a single file
    work_dir: str = ""  # temporary workdir
    includes: Optional[List[str]] = None  # examples to include
    excludes: Optional[List[str]] = None  # examples to exclude
    jobs: int = 1  # Number of concurrent jobs
    tile_sizes: Optional[List[str]] = None  # tile size for each loop depth
    split_non_affine_v2: bool = True  # for array partition v2
    flatten_v2: bool = True  # for array partition v2
    has_non_affine: str = "true"

    # Umbria add
    source_file: str = ""  # input source file (--source-dir)
    keep_only_kernel_no_main_in_mlir: bool = False  # Default False
    clang_no_opt_bin: bool = False  # Default enable clang NO loop unrolling (--disable-loop-unrolling)
    run_bin_on_cpu: bool = False  # Default False
    dump_test_data_cpu: bool = False  # Default False
    enable_papi: bool = False  # Default False
    verify_benchmark_result: bool = False  # Default False
    error_threshold: float = 0.00000001
    only_kernel_transformation: bool = False
