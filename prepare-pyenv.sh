#!/bin/bash

set -e
DEBUG="${RUNNER_DEBUG}"
if [[ "$DEBUG" != "" ]]; then
    set -x
fi

# install dnsrobocert
echo "Installing dnsrobocert..."

sudo apt install -y python3.10-venv
python3 -m pip install pipx
python3 -m pipx ensurepath
python3 -m pipx install dnsrobocert==3.25.0
dnsrobocert --help

