# The OVN Load Balancer

The OVN load balancer is intended to provide very basic load balancing services to workloads
within the OVN logical network space. Due to its simple feature set it is not designed to replace
dedicated appliance-based load balancers which provide many more bells & whistles for
advanced used cases.

The load balancer uses a hash-based algorithm to balance requests for a VIP to an associated pool
of IP addresses within logical space. Since the hash is calculated using the headers of the client
request the balancing should appear fairly random, with each individual client request getting
stuck to a particular member of the load balancing pool for the duration of the connection. Load
balancing in OVN may be applied to either a logical switch or a logical router. The choice of
where to apply the feature depends on your specific requirements. There are caveats to each approach.

When applied to a logical router, the following considerations need to be kept in mind:

1.  Load balancing may only be applied to a “centralized” router (ie. a gateway router).
2.  Due to point #1, load balancing on a router is a non-distributed service.

When applied to a logical switch, the following considerations need to be kept in mind:

1.  Load balancing is “distributed” in that it is applied on potentially multiple OVS hosts.
2.  Load balancing on a logical switch is evaluted only on traffic ingress from a VIF. This means
    that it must be applied on the “client” logical switch rather than on the “server” logical switch.
3.  Due to point #2, you may need to apply the load balancing to many logical switches depending on the
    scale of your design.

**Note, the load balancer is not performing any sort of health checking. At present, the assumption is that health checks would be performed by an orchestration solution such as Kubernetes but it would be resonable to assume that this feature would be added at some future point.**
