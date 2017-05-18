


```sh
# Create logical switches
ovn-nbctl ls-add foo
ovn-nbctl ls-add bar

# Create router
./ovn-router.sh create-router router

# Connect switch "foo" to "router". The router port gets an ip address of
# 192.168.100.1/24
./ovn-router.sh connect-switch router foo 192.168.100.1/24

# Connect switch "bar" to "router. The router port gets an ip address of
# 192.168.200.1/24
./ovn-router.sh connect-switch router bar 192.168.200.1/24

# Create a namespace "foo1" and attach it as a logical port "foo1".
# You need to run this command on the machine you plan to spawn your namespace.
# If that machine is different than the machine where your northbound database
# runs, then you need to provide the --db option, e.g.
#  --db=tcp:10.33.75.67:6640
./ovn-port.sh add-port foo foo1 192.168.100.2/24 192.168.100.1

# Create a namespace "bar1" and attach it as a logical port "bar1"
./ovn-port.sh  add-port --db=tcp:$IP:6640 bar bar1 192.168.200.2/24 192.168.200.1

# Test your pings
ip netns exec foo1 ping 192.168.200.2
```
