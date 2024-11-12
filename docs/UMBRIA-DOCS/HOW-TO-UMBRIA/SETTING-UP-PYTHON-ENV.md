# Pre-requisite system packages

## `pip3`

- check "pip3" availability by

```sh
pip3 --version
```

- If pip3 is not available, then install it by

```sh
sudo apt-get install python3-pip
```

- (Optional) upgrade `pip3`

```sh
sudo -H pip3 install --upgrade pip
```

## `virtualenv`

```sh
sudo pip3 install virtualenv
```


# Creating `python` env

```sh
virtualenv -p python3 py3env
virtualenv -p python py2env
```

# Activate

```sh
# Activate
source py3env/bin/activate

# Deactivate
deactivate
```


# Create python package list file named as `requirements.txt` in src directory

```sh
pip freeze > requirements.txt
```

# Install from python package list

[python pip trouble installing from requirements.txt](https://stackoverflow.com/a/35704416)

```sh
pip install --upgrade -r requirements.txt
```

- Not recommended (Faulty in ubuntu, requirements.txt grabs also other OS dependencies)

```sh
pip install -r requirements.txt
```