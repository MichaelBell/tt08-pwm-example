#!/bin/bash

mpremote connect /dev/ttyACM0 + mount . + exec "import os; os.chdir('/'); import run_pwm; run_pwm.run(query=False, stop=False)"
