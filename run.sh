#!/bin/bash

cd "$(dirname "$0")"
source .venv/bin/activate
exec python main.py -v check-pub --notify --save
