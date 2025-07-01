#!/bin/bash

cd "$(dirname "$0")"
source .venv/bin/activate
exec gunicorn -b unix:/tmp/educanopos.sock -w 4 main:screen_app 
