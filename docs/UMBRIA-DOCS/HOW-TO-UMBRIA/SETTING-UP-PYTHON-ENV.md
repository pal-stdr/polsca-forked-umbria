# Installing Multiple local `python` versions with `pyenv`

## Pre-requisites

```sh
sudo apt-get update

# Mandatory
sudo apt-get install -y libreadline-dev libncurses5-dev libbz2-dev libssl-dev libsqlite3-dev tk-dev

# For libreadline-dev alternative in Ubuntu/Debian
sudo apt install libedit-dev

# If you don't have them
sudo apt-get install -y git make build-essential zlib1g-dev wget xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

## Setting up the [`pyenv`](https://github.com/pyenv/pyenv) src

### Recommended

- Clone/Download the `pyenv` from github to `$HOME/.pyenv` dir. FYI, `~/` is also known as `$HOME` (i.e. `/home/<username>`). Typically in linux, all file/folder name which starts with `.` prefix, are considered as hidden file. Use `Ctrl + h` command to unhide it.

```sh
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
```

- (Optional) Then `cd` to `$HOME/.pyenv` and run the following command. Official doc says, "try to compile a dynamic Bash extension to speed up `pyenv`. Don't worry if it fails; Pyenv will still work normally."

```sh
user@pc-name:/home/user/.pyenv$ src/configure
user@pc-name:/home/user/.pyenv$ make -C src

# Returns
make: Entering directory '/home/user/.pyenv/src'
gcc -fPIC     -c -o realpath.o realpath.c
gcc -shared -Wl,-soname,../libexec/pyenv-realpath.dylib  -o ../libexec/pyenv-realpath.dylib realpath.o 
make: Leaving directory '/home/user/.pyenv/src'
```


### Not Recommended

```sh
curl -fsSL https://pyenv.run | bash
```


## Register the `~/.pyenv` path to your OS env

- Add the following to `~/.profile` (Recommended), or to `~/.bash_profile` (if that exist in your machine), or to `~/.bashrc` (Not Recommended). Then save the file.

```sh
# PYENV
PYENV_BIN_PATH=$HOME/.pyenv/bin
export PATH="$HOME/.pyenv/bin:$PATH"
# Or I use
# export PATH=$PYENV_BIN_PATH${PATH:+:${PATH}}
eval "$(pyenv init --path)"
```

- Logout and login back in the OS (Recommended). If you don't want to logout, run following (Not Recommended)

```sh
exec "$SHELL"
```

- Setting up is done!! 🙂


## Use `pyenv` to install different python version

### Install an example python version `3.10.4`

```sh
pyenv install 3.10.4

# Returns
Downloading Python-3.10.4.tar.xz...
-> https://www.python.org/ftp/python/3.10.4/Python-3.10.4.tar.xz
Installing Python-3.10.4...
Installed Python-3.10.4 to /home/user/.pyenv/versions/3.10.4
```

### Uninstall or Remove

- Uninstall

```sh
pyenv uninstall 3.10.4

# Returns
pyenv: remove /home/user/.pyenv/versions/3.10.4? (y/N) y
pyenv: 3.10.4 uninstalled 
```

- Or, remove

```sh
rm -R ~/.pyenv/versions/3.10.4
```



# Managing python virtual env with `virtualenv`


## Pre-requisite system packages

- **`pip3`**

```sh
# check pip3 availability by

pip3 --version
```

- **If `pip3` is not available, then install it by..**

```sh
sudo apt-get install python3-pip
```

- **(Optional) upgrade `pip3`**

```sh
sudo -H pip3 install --upgrade pip
```

- **Install `virtualenv`**

```sh
sudo pip3 install virtualenv
```

- **Upgrade `virtualenv`**

```sh
# Uninstall first
sudo pip3 uninstall virtualenv

# Returns
Found existing installation: virtualenv x.x.x
Uninstalling virtualenv-x.x.x:
  Would remove:
    /usr/local/bin/virtualenv
    /usr/local/lib/python3.8/dist-packages/virtualenv-x.x.x.dist-info/*
    /usr/local/lib/python3.8/dist-packages/virtualenv/*
Proceed (Y/n)? y
  Successfully uninstalled virtualenv-x.x.x


# Reinstall
sudo pip3 install virtualenv
```




# Creating `python` env with `virtualenv`

## Note:

## How to use `virtualenv`?

```sh
virtualenv -p python3 py3env
virtualenv -p python py2env


# Or to use specified version
virtualenv -p ~/.pyenv/versions/3.10.4/bin/python py3env
```

## Activate or Deactivate

```sh
# Activate
source py3env/bin/activate

# Deactivate
deactivate
```


# Create python package list file named as `requirements.txt` in src directory

- Donot do it if you already have populated. `requirements.txt`.

```sh
pip freeze > requirements.txt
```


# Install from python package list

- Just install the packages with exact version .(requirements.txt grabs also other OS dependencies in Ubuntu)

```sh
pip install -r requirements.txt
```


-If you also want to upgrade the pip packages.

[python pip trouble installing from requirements.txt](https://stackoverflow.com/a/35704416)

```sh
pip install --upgrade -r requirements.txt
```