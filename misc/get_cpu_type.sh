cat /proc/cpuinfo | grep -m 1 "model name" | awk -F':' '{print $2}'
xm info | grep nr_cpus | awk '{print $3}'
