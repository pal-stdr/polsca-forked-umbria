#!/usr/bin/env python3
# A python version of the old pb-flow. Should be way faster with parallelism!
#
# USE: cd $PHSIM \
#      && PYTHONPATH=$PWD \
#      && python3 scripts/pb-flow.py -c example/polybench

import argparse

from pyphism_umbria_cpu_flow.polybench import pb_flow


def main():
    """Main entry"""
    parser = argparse.ArgumentParser(description="Run Polybench experiments")
    # parser.add_argument("source_dir", type=str, help="Polybench directory")
    parser.add_argument("--source-dir", type=str, help="Polybench directory")
    parser.add_argument("--work-dir", type=str, help="The temporary work directory.")
    parser.add_argument(
        "-e", "--examples", nargs="+", default=[], help="Polybench examples to run."
    )
    parser.add_argument(
        "--excl", nargs="+", default=[], help="Polybench examples not to run."
    )
    parser.add_argument("--cfg", type=str, help="Configuration file.")
    parser.add_argument(
        "--dry-run", action="store_true", help="Only produce the commands to run."
    )
    parser.add_argument("-d", "--debug", action="store_true", help="Enable debug mode")
    parser.add_argument(
        "-p",
        "--polymer",
        action="store_true",
        help="Use Polymer to perform polyhedral transformation",
    )
    parser.add_argument(
        "-c", "--cosim", action="store_true", help="Enable co-simulation"
    )
    parser.add_argument(
        "-j", "--jobs", type=int, default=1, help="Number of parallel jobs (default: 1)"
    )
    parser.add_argument(
        "--dataset",
        choices=pb_flow.POLYBENCH_DATASETS,
        default="MINI",
        help="Polybench dataset size. ",
    )
    parser.add_argument("--cleanup", action="store_true", help="Cleanup after run.")
    parser.add_argument(
        "--max-span", type=int, default=-1, help="Max spanning of the point loops."
    )
    parser.add_argument(
        "--split", type=str, default="NO_SPLIT", help="Statement split method."
    )
    parser.add_argument(
        "--improve-pipelining",
        action="store_true",
        help="Enable pipelining improvement",
    )
    parser.add_argument(
        "--loop-transforms",
        "--lt",
        default=False,
        action="store_true",
        help="Enable loop transforms. If this is enabled, --scop-statement-inline will be automatically disabled. Because it also does the inlining.",
    )
    parser.add_argument(
        "--tile-sizes", nargs="+", default=[], help="Tile sizes for each loop nest."
    )
    parser.add_argument(
        "--array-partition", "--ap", action="store_true", help="Use array partition."
    )
    parser.add_argument(
        "--array-partition-v2",
        "--ap-v2",
        action="store_true",
        help="Use array partition (v2).",
    )
    parser.add_argument("--skip-vitis", action="store_true", help="Don't run Vitis.")
    parser.add_argument(
        "--skip-csim", action="store_true", help="Don't run tbgen (csim)."
    )
    parser.add_argument("--sanity-check", action="store_true", help="Run sanity check.")
    parser.add_argument("--cloogl", type=int, default=-1, help="-cloogl option")
    parser.add_argument("--cloogf", type=int, default=-1, help="-cloogf option")
    parser.add_argument(
        "--diamond-tiling", action="store_true", help="Use diamond tiling"
    )

    # Umbria add
    parser.add_argument(
        "--dump-test-data-cpu",
        action="store_true",
        help="This will dump the *.golden.out result to test.",
    )

    parser.add_argument(
        "--only-kernel-transformation",
        action="store_true",
        help="Only transform the kernel. No host"
    )    

    parser.add_argument(
        "--clang-no-opt-bin",
        action="store_true",
        help="No optimization (i.e. -fno-unroll-loops -fno-vectorize -fno-slp-vectorize -fno-tree-vectorize).",
    )

    parser.add_argument(
        "--run-bin-on-cpu",
        action="store_true",
        help="Will run the cpu bin on cpu.",
    )

    parser.add_argument(
        "--enable-papi",
        action="store_true",
        help="benchmark cpu execution with papi.",
    )

    parser.add_argument(
        "--verify-benchmark-result",
        action="store_true",
        help="Verify the result from the polybench benchmark.",
    )

    parser.add_argument(
        "--error-threshold",
        type=float,
        default=0.00000001,
        help="Set float error threshold to verify the result."
    )

    parser.add_argument(
        "--dump-csv-report",
        action="store_true",
        help="Only transform the kernel. No host"
    )

    args = parser.parse_args()

    options = pb_flow.PbFlowOptions(**vars(args))

    print(f"Options: {options}")

    pb_flow.pb_flow_runner(options, options.dump_csv_report)


if __name__ == "__main__":
    main()
