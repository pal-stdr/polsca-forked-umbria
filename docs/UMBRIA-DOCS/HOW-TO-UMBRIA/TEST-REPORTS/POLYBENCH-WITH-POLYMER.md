
```sh
PYTHONPATH=/path/to/polsca-forked-umbria python3 scripts/umbria-scripts/umbria-flow-with-xilinx.py -c -p -j 20 example/polybench --work-dir ./tmp-umbria/polybench-with-polymer/umbria-pb-flow.tmp --cosim


Options: PbFlowOptions(key='', source_file='', top_func='', incl_funcs='', disabled=None, cfg=None, polymer=True, loop_transforms=False, array_partition=False, fold_if=False, skip_vitis=False, cosim=True, dry_run=False, sanity_check=False, source_dir='example/polybench', work_dir='./tmp-umbria/polybench-with-polymer/umbria-pb-flow.tmp', includes=None, excludes=None, jobs=20, tile_sizes=[], split_non_affine_v2=True, flatten_v2=True, has_non_affine='true', cloogf=-1, cloogl=-1, diamond_tiling=False, dataset='MINI', cleanup=False, debug=False, examples=[], excl=[], split='NO_SPLIT', coalescing=False, constant_args=True, improve_pipelining=False, max_span=-1, skip_csim=False, array_partition_v2=False)


>>> Starting 20 jobs (work_dir=./tmp-umbria/polybench-with-polymer/umbria-pb-flow.tmp) ...
>>> Finished bicg            elapsed: 108.435380 secs   Status: 0  Error: "No Error"
>>> Finished atax            elapsed: 119.675375 secs   Status: 0  Error: "No Error"
>>> Finished deriche         elapsed: 1.181931 secs   Status: 1  Error: "/path/to/polsca-forked-umbria/polsca-build/bin/phism-opt /path/to/polsca-forked-umbria/tmp-umbria/polybench-with-polymer/umbria-pb-flow.tmp/medley/deriche/deriche.pre.mlir -extract-top-func="name=kernel_deriche keepall=False"  -debug failed."
>>> Finished mvt             elapsed: 125.897726 secs   Status: 0  Error: "No Error"
>>> Finished gesummv         elapsed: 144.559622 secs   Status: 0  Error: "No Error"
>>> Finished trmm            elapsed: 144.736066 secs   Status: 0  Error: "No Error"
>>> Finished doitgen         elapsed: 150.076636 secs   Status: 0  Error: "No Error"
>>> Finished durbin          elapsed: 151.944431 secs   Status: 0  Error: "No Error"
>>> Finished syr2k           elapsed: 157.557478 secs   Status: 0  Error: "No Error"
>>> Finished gemver          elapsed: 167.842945 secs   Status: 0  Error: "No Error"
>>> Finished syrk            elapsed: 168.921849 secs   Status: 0  Error: "No Error"
>>> Finished 3mm             elapsed: 170.020928 secs   Status: 0  Error: "No Error"
>>> Finished covariance      elapsed: 170.263861 secs   Status: 0  Error: "No Error"
>>> Finished gramschmidt     elapsed: 185.467694 secs   Status: 0  Error: "No Error"
>>> Finished gemm            elapsed: 194.066083 secs   Status: 0  Error: "No Error"
>>> Finished floyd-warshall  elapsed: 75.751121 secs   Status: 0  Error: "No Error"
>>> Finished 2mm             elapsed: 198.471625 secs   Status: 0  Error: "No Error"
>>> Finished nussinov        elapsed: 73.458144 secs   Status: 0  Error: "No Error"
>>> Finished ludcmp          elapsed: 201.137242 secs   Status: 0  Error: "No Error"
>>> Finished symm            elapsed: 202.585234 secs   Status: 0  Error: "No Error"
>>> Finished correlation     elapsed: 204.462023 secs   Status: 0  Error: "No Error"
>>> Finished cholesky        elapsed: 208.322896 secs   Status: 0  Error: "No Error"
>>> Finished lu              elapsed: 211.297143 secs   Status: 0  Error: "No Error"
>>> Finished trisolv         elapsed: 116.772779 secs   Status: 0  Error: "No Error"
>>> Finished jacobi-1d       elapsed: 81.536526 secs   Status: 0  Error: "No Error"
>>> Finished fdtd-2d         elapsed: 201.961091 secs   Status: 0  Error: "No Error"
>>> Finished jacobi-2d       elapsed: 252.810476 secs   Status: 0  Error: "No Error"
>>> Finished seidel-2d       elapsed: 294.769315 secs   Status: 0  Error: "No Error"
>>> Finished heat-3d         elapsed: 341.157408 secs   Status: 0  Error: "No Error"
>>> Finished adi             elapsed: 457.738976 secs   Status: 0  Error: "No Error"
Elapsed time: 602.328512 sec
>>> Dumping report ... 




              name   status  latency DSP_usage FF_usage LUT_usage BRAM_18K_usage URAM_usage DSP_avail FF_avail LUT_avail BRAM_18K_avail URAM_avail
0              2mm  SUCCESS    15284         0      221       107              0          0      2520   548160    274080           1824          0
1              3mm  SUCCESS    22664         0       21       169              0          0      2520   548160    274080           1824          0
2              adi  SUCCESS   115181         0      436       400              0          0      2520   548160    274080           1824          0
3             atax  SUCCESS    14060        19     2236      3159              0          0      2520   548160    274080           1824          0
4             bicg  SUCCESS    14180         1      561       487              0          0      2520   548160    274080           1824          0
5         cholesky  SUCCESS    90877        20     4709      7056              0          0      2520   548160    274080           1824          0
6      correlation  SUCCESS    52397         0      119        91              0          0      2520   548160    274080           1824          0
7       covariance  SUCCESS    56029         0      248       234              0          0      2520   548160    274080           1824          0
8          deriche   NO_LOG     None      None     None      None           None       None      None     None      None           None       None
9          doitgen  SUCCESS    16481         0        6        48              0          0      2520   548160    274080           1824          0
10          durbin  SUCCESS     7412         0       91       154              0          0      2520   548160    274080           1824          0
11         fdtd-2d  SUCCESS   465807         0     1281      1267              0          0      2520   548160    274080           1824          0
12  floyd-warshall  SUCCESS   433201         4      485      1299              0          0      2520   548160    274080           1824          0
13            gemm  SUCCESS    15518         1      251       176              0          0      2520   548160    274080           1824          0
14          gemver  SUCCESS    24057         0     1538       885              0          0      2520   548160    274080           1824          0
15         gesummv  SUCCESS      683         3     5173      2998              0          0      2520   548160    274080           1824          0
16     gramschmidt  SUCCESS    75208         0      124       127              0          0      2520   548160    274080           1824          0
17         heat-3d  SUCCESS   606415         0     1646      1228              0          0      2520   548160    274080           1824          0
18       jacobi-1d  SUCCESS    18225        14     2054      3774              0          0      2520   548160    274080           1824          0
19       jacobi-2d  SUCCESS   761410         0      683       494              0          0      2520   548160    274080           1824          0
20              lu  SUCCESS   156240         0      518       501              0          0      2520   548160    274080           1824          0
21          ludcmp  SUCCESS   125523         0      273       132              0          0      2520   548160    274080           1824          0
22             mvt  SUCCESS     7447        14     1339      1320              0          0      2520   548160    274080           1824          0
23        nussinov  SUCCESS    85976         0      264       544              0          0      2520   548160    274080           1824          0
24       seidel-2d  SUCCESS  1810407         4     2739      5183              0          0      2520   548160    274080           1824          0
25            symm  SUCCESS    45657         0      545       300              0          0      2520   548160    274080           1824          0
26           syr2k  SUCCESS     9047       100    16313      8461              0          0      2520   548160    274080           1824          0
27            syrk  SUCCESS     8897         6     4531      3292              0          0      2520   548160    274080           1824          0
28         trisolv  SUCCESS     5971        17     2152      3107              0          0      2520   548160    274080           1824          0
29            trmm  SUCCESS     9215        39     6612      4774              0          0      2520   548160    274080           1824          0


```