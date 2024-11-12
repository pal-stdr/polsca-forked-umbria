# POLSCA-UMBRIA: Polyhedral High-Level Synthesis code emitter from MLIR

- You can find the original README.md here [README-ORIGINAL.md](README-ORIGINAL.md).



# 1. INSTALL PRE-REQUISITE PACKAGES (`apt-get` packages) FOR Polygesit + PLUTO + Polymer

- Please read [docs/UMBRIA-DOCS/HOW-TO-UMBRIA/1.SETTING-UP-PREREQUISITES.md](docs/UMBRIA-DOCS/HOW-TO-UMBRIA/1.SETTING-UP-PREREQUISITES.md)




# 2. Build `llvm-9` (for `pluto` in `polymer`), `llvm-14` (for `polygeist`, `polymer`, `polsca`), `polygeist`, `polymer`, and `polsca`

- Please read [docs/UMBRIA-DOCS/HOW-TO-UMBRIA/2.BUILD-LLVM-POLYGEIST-POLYMER-POLSCA.md](docs/UMBRIA-DOCS/HOW-TO-UMBRIA/2.BUILD-LLVM-POLYGEIST-POLYMER-POLSCA.md)




# 3. How to run

## 3.1. Initiate python env

```sh
# Initiate env in polsca root
virtualenv -p python3 py3env


# Activate
source py3env/bin/activate
# You will see something like following
# (py3env) username@pcname:/path/to/polsca-root$



# Install packages
pip install -r requirements.txt


# Deactivate (if you want)
# Donot install any packages when it is deactivated
deactivate
```


## 3.2.

```sh
make test-one-example-with-umbria-with-xilinx-hls

make test-one-polymer-example-with-umbria-with-xilinx-hls
```