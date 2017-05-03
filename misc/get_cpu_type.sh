#!/bin/bash
cat /proc/cpuinfo | grep -m 1 "model name" | awk -F':' '{print $2}'
