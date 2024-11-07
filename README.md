# POLSCA-UMBRIA: Polyhedral High-Level Synthesis code emitter from MLIR

- You can find the original README.md here [README-ORIGINAL.md](README-ORIGINAL.md).



# 1. INSTALL PRE-REQUISITE PACKAGES (`apt-get` packages and `llvm-9`) FOR Polygesit + PLUTO + Polymer

- Please read [docs/UMBRIA-DOCS/HOW-TO-UMBRIA/1.SETTING-UP-PREREQUISITES.md](docs/UMBRIA-DOCS/HOW-TO-UMBRIA/1.SETTING-UP-PREREQUISITES.md)



# 2. CLONE `polsca-forked-umbria`

```sh
git clone https://github.com/pal-stdr/polsca-forked-umbria.git
```


# 3. Recursively load all the submodules

```sh
# Sync first
git submodule sync


git submodule update --init --recursive
```


# 4. Build the `llvm-project` inside `polygeist` (i.e. `polygeist/llvm-project`)

- **This script will create 2 folders in your project-root: `llvm-build-for-polygeist-polymer-polsca/` & `llvm-build-for-polygeist-polymer-polsca-installation/`**.

```sh
./scripts/umbria-scripts/build-llvm.sh
```


# 5. Build the `polygeist`

- **This script will create 2 folders in your project-root: `polygeist-build-for-polsca/` & `polygeist-build-for-polsca-installation/`**.

```sh
./scripts/umbria-scripts/build-polygeist.sh
```